require 'fileutils'
require 'pathname'
require_relative 'common.rb'

module Xtrabackup

  # prepares the latest available backup
  def self.prepare(output_dir, backup_base_dir, backup_dir=nil, no_date_dir=false)
    self.assert_arg_not_empty(method(__method__).parameters[0][1], output_dir)
    self.assert_arg_not_empty(method(__method__).parameters[1][1], backup_base_dir)
    if backup_dir.nil?
      self.prepare_latest(output_dir, backup_base_dir, no_date_dir)
    else
      self.prepare_specific(output_dir, backup_base_dir, backup_dir, no_date_dir)
    end
  end

  # prepares the latest available backup
  def self.prepare_latest(output_dir, backup_base_dir, no_date_dir)
    full_backups = self.find_backups(self.full_backup_path(backup_base_dir))
    raise "Cannot prepare backup: No full backup found in #{backup_base_dir}" if full_backups.empty?

    last_full = full_backups.last
    inc_backups = self.find_backups(self.incremental_backup_path(backup_base_dir))

    if inc_backups.empty?
      puts 'No incremental backups found: Preparing the latest full backup...'
      self.prepare_full(output_dir, last_full, no_date_dir)
    elsif inc_backups.last.to_lsn <= last_full.to_lsn
      puts 'Latest incremental backup <= latest full backup: Preparing the latest full backup...'
      self.prepare_full(output_dir, last_full, no_date_dir)
    else
      puts 'Preparing the latest incremental backup...'
      self.prepare_incremental(output_dir, full_backups, inc_backups.last, inc_backups, no_date_dir)
    end

  end

  # prepares a specific backup.
  def self.prepare_specific(output_dir, backup_base_dir, backup_dir, no_date_dir)
    backup = self.find_backup(backup_dir)

    if backup.class == Xtrabackup::FullBackup
      self.prepare_full(output_dir, backup, no_date_dir)
    elsif backup.class == Xtrabackup::IncBackup
      full_backups = self.find_backups(self.full_backup_path(backup_base_dir))
      inc_backups = self.find_backups(self.incremental_backup_path(backup_base_dir))
      self.prepare_incremental(output_dir, full_backups, backup, inc_backups, no_date_dir)
    end
  end

  private

  def self.prepare_incremental(output_dir, full_backups, inc_backup, all_inc_backups, no_date_dir)
    chain = self.backup_chain_for_increment(inc_backup, all_inc_backups, full_backups)
    last_increment = chain.last

    # give the output subdirectory the name as the latest backup increment has
    dest_dir = self.pre_prepare(output_dir, chain.first, no_date_dir)

    if (!no_date_dir) 
      new_dest_dir = output_dir + File::SEPARATOR + Pathname.new(last_increment.path).basename.to_s
      self.rmdir_if_exists(new_dest_dir)
      FileUtils.mv(dest_dir, new_dest_dir)
      dest_dir = new_dest_dir
    end


    chain.each_with_index do |backup, index|
      if index == 0
        puts "Preparing full backup #{backup.from_lsn} -> #{backup.to_lsn} in #{dest_dir} ..."
        self.innobackupex_cmd("--apply-log --redo-only #{dest_dir}")
      elsif backup == last_increment
        puts "Applying the last increment ##{index} #{backup.from_lsn} -> #{backup.to_lsn} to #{dest_dir} ..."
        self.innobackupex_cmd("--apply-log #{dest_dir} --incremental-dir=#{backup.path}")
      else
        puts "Applying incremental backup ##{index} #{backup.from_lsn} -> #{backup.to_lsn} to #{dest_dir} ..."
        self.innobackupex_cmd("--apply-log --redo-only #{dest_dir} --incremental-dir=#{backup.path}")
      end
    end

    puts "Prepare to rollback uncommited changes in #{dest_dir} ..."
    self.innobackupex_cmd("--apply-log #{dest_dir}")
    puts "Backup preparation finished. You can now halt mysqld and apply it with something like 'innobackupex --copy-back #{dest_dir} && chown -R mysql:mysql /var/lib/mysql'."

  end

  def self.prepare_full(output_dir, backup, no_date_dir)
    dest_dir = self.pre_prepare(output_dir, backup, no_date_dir)
    puts "Preparing full backup in #{dest_dir}..."
    self.innobackupex_cmd( "--apply-log #{dest_dir}")
  end

  def self.pre_prepare(output_dir, full_backup, no_date_dir)
    if ( no_date_dir)
      dest_dir = output_dir
    else
      dest_dir = output_dir + File::SEPARATOR + Pathname.new(full_backup.path).basename.to_s
    end

    self.rmdir_if_exists(dest_dir)

    puts "Copying #{full_backup.path} to #{output_dir}..."
    FileUtils.mkdir_p(output_dir)
    FileUtils.cp_r(full_backup.path + (no_date_dir ? File::SEPARATOR + "." : '') , output_dir)     
    dest_dir
  end

  def self.rmdir_if_exists(dir)
    if File.exists?(dir)
      puts "Directory #{dir} already exists. Deleting it recursively."
      FileUtils.rm_r(dir)
    end
  end
end