require 'rake/rdoctask'

ROOT = '.'
LIB_ROOT = File.join ROOT, 'lib'
EXTRA_RDOC_FILES = %w(lib/README FOLDERS)

task :default => :test

if File.directory? 'rake_tasks'
  
  # load rake tasks from subfolder
  for task_file in Dir['rake_tasks/*.rake'].sort
    load task_file
  end
  
else
  
  # fallback tasks when rake_tasks folder is not present
  desc 'Run CodeRay tests (basic)'
  task :test do
    ruby './test/functional/suite.rb'
    ruby './test/functional/for_redcloth.rb'
  end
  
  desc 'Generate documentation for CodeRay'
  Rake::RDocTask.new :doc do |rd|
    rd.title = 'CodeRay Documentation'
    rd.main = 'lib/README'
    rd.rdoc_files.add Dir['lib']
    rd.rdoc_files.add 'lib/README'
    rd.rdoc_files.add 'FOLDERS'
    rd.rdoc_dir = 'doc'
  end
  
end