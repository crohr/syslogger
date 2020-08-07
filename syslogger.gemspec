# frozen_string_literal: true

require_relative 'lib/syslogger/version'

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

  s.files = `git ls-files`.split("\n")

  s.add_development_dependency 'activejob'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'simplecov'
end
