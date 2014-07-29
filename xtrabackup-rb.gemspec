# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name         = "xtrabackup-rb"
  s.summary      = "Ruby module and command-line wrapper around innobackupex."
  s.description  = <<EOF
Supports full and incremental backups and preparation steps for restoring them.
EOF
  s.requirements = [ 'Ruby - tested with 1.9.3', 'Percona Xtrabackup' ]
  s.version      = File.read('version.txt')
  s.author       = 'Andreas Wirth'
  s.email        = 'andreas.wirth@srf.ch'
  s.homepage     = 'http://TODO'
  s.platform     =  Gem::Platform::RUBY
  s.required_ruby_version = '>=1.9'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.has_rdoc     = false
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
end