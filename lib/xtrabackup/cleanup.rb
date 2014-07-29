require 'fileutils'
require_relative 'common.rb'

module Xtrabackup

  def self.cleanup(dir, keep)
    chains = self.backup_chains(dir)
    to_delete = chains.reverse[keep..-1] if chains
    remaining = chains - to_delete
    remaining.reverse!

    to_delete.each do |chain|
      chain.reverse!
      chain.each do |backup|
        case backup
          when Xtrabackup::FullBackup
            FileUtils.rm_r(backup.path)
            puts "#{backup.from_lsn} -> #{backup.to_lsn}#{' '*13}#{backup.path} DELETED"
          when Xtrabackup::IncBackup
            contained_in_other = self.contains(remaining, backup)
            FileUtils.rm_r(backup.path) if not contained_in_other
            puts "  -> #{backup.from_lsn} -> #{backup.to_lsn}#{' '*2}#{backup.path} #{contained_in_other ? 'NOT DELETED' : 'DELETED'}"
        end
      end if to_delete
      puts
    end
  end


  private

  def self.contains(chains, backup)
    result = false
    chains.each do |chain|
      if chain.include?(backup)
        result = true
        break
      end
    end
    result
  end

end