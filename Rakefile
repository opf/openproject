require "spec/rake/spectask"
require "rake/clean"
require "rake/rdoctask"

task :default => :spec
task :test => :spec

Rake::RDocTask.new("rdoc") do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.options += %w[--all --inline-source --line-numbers --main README.rdoc --quiet --tab-width 2]
  rdoc.rdoc_files.add Dir['*.{rdoc,rb}', '{app,lib}/**/*.rb']
end

Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = Dir.glob 'spec/**/*_spec.rb'
end