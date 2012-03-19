# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'syslogger'
 
Gem::Specification.new do |s|
  s.name                      = "syslogger"
  s.version                   = Syslogger::VERSION
  s.platform                  = Gem::Platform::RUBY
  s.required_ruby_version     = '>= 1.8'
  s.required_rubygems_version = ">= 1.3"
  s.authors                   = ["Cyril Rohr"]
  s.email                     = ["cyril.rohr@gmail.com"]
  s.homepage                  = "http://github.com/crohr/syslogger"
  s.summary                   = "Dead simple Ruby Syslog logger"
  s.description               = "Same as SyslogLogger, but without the ridiculous number of dependencies and with the possibility to specify the syslog facility"
  
  s.add_development_dependency('rake', '~> 0.9')
  s.add_development_dependency('rspec', '~> 2.0')
  s.add_development_dependency('rdoc')
 
  s.files        = Dir.glob("{lib,spec}/**/*") + %w(Rakefile LICENSE README.rdoc)
  
  s.test_files = [
    "spec/spec_helper.rb",
     "spec/syslogger_spec.rb"
  ]
  
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_path = 'lib'
end
