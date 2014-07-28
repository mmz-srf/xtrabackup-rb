module Xtrabackup

  class Backup
    attr_reader :path, :from_lsn, :to_lsn, :compact

    def initialize(path, from_lsn, to_lsn, compact)
      @path = path
      @from_lsn = from_lsn
      @to_lsn = to_lsn
      @compact = compact
    end

    def <=>(another)
      if self.to_lsn < another.to_lsn
        -1
      elsif self.to_lsn > another.to_lsn
        1
      else
        0
      end
    end

    def ==(another)
      self.path == another.path
    end

  end

  class FullBackup < Backup
  end

  class IncBackup < Backup
  end
end