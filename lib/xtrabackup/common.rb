module Xtrabackup
  SUBDIR_FULL = 'full'
  SUBDIR_INC = 'inc'
  INNOBACKUPEX = 'innobackupex'
  CHECKPOINTS_FILE = 'xtrabackup_checkpoints'

  private

  # Factory methods that creates an instance of Xtrabackup::Backup.
  def self.find_backup(path)
    checkpoints_file = path + File::SEPARATOR + CHECKPOINTS_FILE
    if File.exists?(checkpoints_file)
      h = Hash[*File.read(checkpoints_file).split(/[= \n]+/)]
      case h['backup_type']
        when 'incremental' then IncBackup.new(path, h['from_lsn'], h['to_lsn'], h['compact'])
        when 'full-backuped' then FullBackup.new(path, h['from_lsn'], h['to_lsn'], h['compact'])
      end
    end
  end

  # Factory methods that creates a sorted Array containing instances of Xtrabackup::Backup
  def self.find_backups(path)
    Dir.entries(path).map do |subdir|
      if subdir.chars.first != '.'
        self.find_backup(path + File::SEPARATOR + subdir)
      end
    end.compact.sort
  end

  # Returns an Array with a Xtrabackup:FullBackup at index 0 followed
  # by 0-n Xtrabackup:IncBackup instances
  def self.backup_chain_for_full(full_backup, increments)
    chain = []
    chain << full_backup

    increment_candidates = increments.select {|incr| incr.from_lsn >= full_backup.to_lsn}
    increment_candidates.sort! {|a,b| b.from_lsn <=> a.from_lsn }

    while !increment_candidates.empty?
      candidate = increment_candidates.pop
      if candidate.from_lsn == chain.last.to_lsn
        chain << candidate
      end
    end

    chain
  end

  # Returns an Array with a Xtrabackup:FullBackup at index 0 followed
  # by 0-n Xtrabackup:IncBackup instances
  def self.backup_chain_for_increment(increment, all_increments, full_backups)
    chain = []
    chain << increment

    increment_candidates = all_increments.select{|inc| inc.to_lsn < increment.to_lsn}
    full_backup = nil

    while !increment_candidates.empty? and full_backup.nil?
      candidate = increment_candidates.pop
      if candidate.to_lsn == chain.last.from_lsn
        chain << candidate
      end
    end

    full_backup = full_backups.find {|b| b.to_lsn == chain.first.from_lsn}
    full_backup ? chain << full_backup : chain = []
    chain.reverse
  end

  def self.full_backup_path(dir)
    dir + File::SEPARATOR + SUBDIR_FULL
  end

  def self.incremental_backup_path(dir)
    dir + File::SEPARATOR + SUBDIR_INC
  end

  def self.innobackupex_cmd(args)
    out = `#{INNOBACKUPEX} #{args} 2>&1`
    lines = out.split(/\n/)
    begin
      path = lines[-3].scan(/'(.+)'/).first.first
    rescue
      path = nil
    end
    lastline = lines.last
    success = $?.exitstatus == 0 and lastline =~ /completed OK!$/
    raise "#{INNOBACKUPEX} failed: #{lastline}" if !success
    path
  end

  def self.innobackupex_args_credentials(username=nil, password=nil)
    result = ''
    result << "--user=#{username}" if username
    result << ' ' if !result.empty?
    result << "--password=#{password}" if password
    result
  end

end