require 'rake/testtask'

task :default => %w(test)

desc 'Run tests with minitest'
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
end

desc 'Generate mime tables'
task :tables => 'lib/mimemagic/tables.rb'
file 'lib/mimemagic/tables.rb' => FileList['script/freedesktop.org.xml'] do |f|
  sh "script/generate-mime.rb #{f.prerequisites.join(' ')} > #{f.name}"
end

