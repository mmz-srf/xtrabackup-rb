require 'fileutils'
require 'pathname'
require_relative 'common.rb'

module Xtrabackup

  # prepares the latest available backup
  def self.prepare(output_dir, backup_base_dir, backup_dir=nil, username=nil, password=nil)
    if backup_dir.nil?
      self.prepare_latest(output_dir, backup_base_dir, username, password)
    else
      self.prepare_specific(output_dir, backup_dir, username, password)
    end
  end

  # prepares the latest available backup
  def self.prepare_latest(output_dir, backup_base_dir, username=nil, password=nil)
    full_backups = self.find_backups(backup_base_dir + File::SEPARATOR + SUBDIR_FULL)
    raise "Cannot prepare backup: No full backup found in #{backup_base_dir}" if full_backups.empty?

    last_full = full_backups.last
    inc_backups = self.find_backups(backup_base_dir + File::SEPARATOR + SUBDIR_INC)

    if inc_backups.empty?
      puts 'No incremental backups found: Preparing the latest full backup...'
      self.prepare_full(output_dir, last_full, username, password)
    elsif inc_backups.last.to_lsn <= last_full.to_lsn
      puts 'Latest incremental backup <= latest full backup: Preparing the latest full backup...'
      self.prepare_full(output_dir, last_full, username, password)
    else
      puts 'Preparing the latest incremental backup...'
      self.prepare_incremental(output_dir, full_backups, inc_backups.last, inc_backups, username, password)
    end

  end

  # prepares a specific backup.
  def self.prepare_specific(output_dir, full_backups, inc_backup, username=nil, password=nil)
    puts "Preparing a specific backup is not implemented yet."
    exit 1
  end

  private

  def self.prepare_incremental(output_dir, full_backups, inc_backup, all_inc_backups, username=nil, password=nil)
    chain = self.backup_chain_for_increment(inc_backup, all_inc_backups, full_backups)
    last_increment = chain.last

    # give the output subdirectory the name as the latest backup increment has
    dest_dir = self.pre_prapare(output_dir, chain.first)
    new_dest_dir = output_dir + File::SEPARATOR + Pathname.new(last_increment.path).basename.to_s
    self.rmdir_if_exists(new_dest_dir)
    FileUtils.mv(dest_dir, new_dest_dir)
    dest_dir = new_dest_dir

    chain.each_with_index do |backup, index|
      if index == 0
        puts "Preparing full backup #{backup.from_lsn} -> #{backup.to_lsn} in #{dest_dir} ..."
        self.innobackupex_cmd(self.innobackupex_args_credentials(username, password) + " --apply-log --redo-only #{dest_dir}")
      elsif backup == last_increment
        puts "Applying the last increment ##{index} #{backup.from_lsn} -> #{backup.to_lsn} to #{dest_dir} ..."
        self.innobackupex_cmd(self.innobackupex_args_credentials(username, password) + " --apply-log #{dest_dir} --incremental-dir=#{backup.path}")
      else
        puts "Applying incremental backup ##{index} #{backup.from_lsn} -> #{backup.to_lsn} to #{dest_dir} ..."
        self.innobackupex_cmd(self.innobackupex_args_credentials(username, password) + " --apply-log --redo-only #{dest_dir} --incremental-dir=#{backup.path}")
      end
    end

  end

  def self.prepare_full(output_dir, backup, username=nil, password=nil)
    dest_dir = self.pre_prapare(output_dir, backup)
    puts "Preparing full backup in #{dest_dir}..."
    self.innobackupex_cmd(self.innobackupex_args_credentials(username, password) + " --apply-log #{dest_dir}")
  end

  def self.pre_prapare(output_dir, full_backup)
    dest_dir = output_dir + File::SEPARATOR + Pathname.new(full_backup.path).basename.to_s
    self.rmdir_if_exists(dest_dir)

    puts "Copying #{full_backup.path} to #{output_dir}..."
    FileUtils.mkdir_p(output_dir)
    FileUtils.cp_r(full_backup.path, output_dir)
    dest_dir
  end

  def self.rmdir_if_exists(dir)
    if File.exists?(dir)
      puts "Directory #{dir} already exists. Deleting it recursively."
      FileUtils.rm_r(dir)
    end
  end
end