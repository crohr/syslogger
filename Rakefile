require 'rspec/core/rake_task'
require 'rake/rdoctask'

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

RSpec::Core::RakeTask.new(:spec) do |spec|
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.rcov = true
end

Rake::RDocTask.new do |rdoc|
  require 'syslogger'
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "syslogger #{Syslogger::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => :spec
