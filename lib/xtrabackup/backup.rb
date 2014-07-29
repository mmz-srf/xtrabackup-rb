require 'fileutils'
require_relative 'common.rb'
require_relative 'domain.rb'

module Xtrabackup

  def self.innobackupex(type, dir, username=nil, password=nil)
    case type
      when 'full' then innobackupex_full(dir, username, password)
      when 'incremental' then innobackupex_incremental(dir, username, password)
      else raise ArgumentError, "Backup type has to be either 'full' or 'incremental'"
    end
  end

  def self.innobackupex_full(dir, username=nil, password=nil)
    self.assert_arg_not_empty(method(__method__).parameters[0][1], dir)

    full_backup_dir = self.full_backup_path(dir)
    FileUtils.mkdir_p(full_backup_dir)

    puts "Performing full backup..."
    path = self.innobackupex_cmd(self.innobackupex_args_credentials(username, password) << ' ' << full_backup_dir)
    puts "Full backup finished: #{path}"
  end

  def self.innobackupex_incremental(dir, username=nil, password=nil)
    self.assert_arg_not_empty(method(__method__).parameters[0][1], dir)

    last_full_backup = self.find_backups(self.full_backup_path(dir)).last
    raise "No full backup found. Do a full backup first!" if !last_full_backup

    inc_backup_dir = self.incremental_backup_path(dir)
    FileUtils.mkdir_p(inc_backup_dir)

    latest_increment = self.backup_chain_for_full(last_full_backup, self.find_backups(inc_backup_dir)).last
    incremental_basedir = latest_increment ? latest_increment.path : last_full_backup.path

    puts "Performing incremental backup..."
    path = self.innobackupex_cmd(self.innobackupex_args_credentials(username, password) << " --incremental #{inc_backup_dir} --incremental-basedir=#{incremental_basedir}")
    backup = self.find_backup(path)

    if backup.from_lsn == backup.to_lsn
      puts "Backup increment with from_lsn == to_lsn. Deleting it..."
      FileUtils.rm_r(path)
    else
      puts "Incremental backup finished: #{path}"
    end

  end

end
