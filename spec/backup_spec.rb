require 'spec_helper'
require 'fileutils'

describe Xtrabackup do

  describe "#innobackupex" do

    it 'raises an ArgumentError if arg type != full or incremental' do
      expect{Xtrabackup.innobackupex('unsupported', '/dev/rspec')}.to raise_error(ArgumentError)
    end

    it 'invokes innobackupex_full if arg type == :full' do
      allow(Xtrabackup).to receive(:innobackupex_full)
      expect(Xtrabackup).to receive(:innobackupex_full).with('/dev/rspec', nil, nil)
      Xtrabackup.innobackupex('full', '/dev/rspec')
    end

    it 'invokes innobackupex_incremental if arg type == :incremental' do
      allow(Xtrabackup).to receive(:innobackupex_incremental)
      expect(Xtrabackup).to receive(:innobackupex_incremental).with('/dev/rspec', nil, nil)
      Xtrabackup.innobackupex('incremental', '/dev/rspec')
    end

  end

  describe "#innobackupex_full assertions" do

    it 'raises an ArgumentError if a param dir is nil' do
     expect{Xtrabackup.innobackupex_full(nil)}.to raise_error(ArgumentError)
    end

    it 'raises an ArgumentError if a param dir is empty' do
      expect{Xtrabackup.innobackupex_full('')}.to raise_error(ArgumentError)
    end

    it 'raises an ArgumentError if a param dir consists of blanks' do
      expect{Xtrabackup.innobackupex_full('  ')}.to raise_error(ArgumentError)
    end

  end

end