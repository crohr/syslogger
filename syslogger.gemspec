# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'syslogger/version'

Gem::Specification.new do |s|
  s.name        = 'syslogger'
  s.version     = Syslogger::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Cyril Rohr']
  s.email       = ['cyril.rohr@gmail.com']
  s.homepage    = 'http://github.com/crohr/syslogger'
  s.summary     = 'Dead simple Ruby Syslog logger'
  s.description = 'Same as SyslogLogger, but without the ridiculous number of dependencies and with the possibility to specify the syslog facility'
  s.license     = 'MIT'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rdoc'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.rdoc_options = ['--charset=UTF-8']
end
