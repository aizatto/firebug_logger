require 'rake'
require 'rake/rdoctask'

desc 'Default: Generate documnetation.'
task :default => :rdoc

desc 'Generate documentation for the firebug_logger plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'FirebugLogger'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('MIT-LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
