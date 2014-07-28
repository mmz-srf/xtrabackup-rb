require_relative 'common.rb'

module Xtrabackup

  def self.list(dir)
    full_backups = self.find_backups(self.full_backup_path(dir))
    inc_backups = self.find_backups(self.incremental_backup_path(dir))

    full_backups.each do |full|
      chain = self.backup_chain_for_full(full, inc_backups)
      chain.each do |backup|
        prefix = backup != full ? '  -> ' : ''
        puts "#{prefix}#{backup.from_lsn} -> #{backup.to_lsn}\t #{backup.path}"
      end
      puts
    end
  end

end