require_relative 'common.rb'
require_relative 'domain.rb'

module Xtrabackup

  def self.print_chains(dir)
    self.backup_chains(dir).each do |chain|
      chain.each do |backup|
        case backup
          when Xtrabackup::FullBackup
            puts "#{backup.from_lsn} -> #{backup.to_lsn}#{' '*13}#{backup.path}"
          when Xtrabackup::IncBackup
            puts "  -> #{backup.from_lsn} -> #{backup.to_lsn}#{' '*2}#{backup.path}"
        end
      end
      puts
    end

  end
end