# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rdoc/task'

RSpec::Core::RakeTask.new(:spec)
task default: :spec

Rake::RDocTask.new do |rdoc|
  require 'syslogger'
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "syslogger #{Syslogger::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
