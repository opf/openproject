require 'rake'
require 'rake/clean'
require 'rake/testtask'

CLEAN.include('**/*.gem', '**/*.rbc', '**/*.rbx')

desc "Run the test suite"
Rake::TestTask.new("test") do |t|
  if File::ALT_SEPARATOR
    t.libs << 'lib/windows'
  else
    t.libs << 'lib/unix'
  end

  t.warning = true
  t.verbose = true
  t.test_files = FileList['test/test_sys_filesystem.rb']
end

desc "Run the example program"
task :example do |t|
  sh "ruby -Ilib -Ilib/unix -Ilib/windows examples/example_stat.rb"
end

namespace :gem do
  desc "Build the sys-filesystem gem"
  task :create => [:clean] do |t|
    require 'rubygems/package'
    spec = eval(IO.read('sys-filesystem.gemspec'))
    spec.signing_key = File.join(Dir.home, '.ssh', 'gem-private_key.pem')
    Gem::Package.build(spec, true)
  end

  desc "Install the sys-filesystem gem"
  task :install => [:create] do
    file = Dir['*.gem'].first
    sh "gem install -l #{file}"
  end
end

task :default => :test
