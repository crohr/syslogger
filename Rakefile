require 'spec/rake/spectask'
require 'rake/rdoctask'

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
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
