require 'rake/clean'
require 'rake/testtask'

task :default => :test

# TESTS #######################################################################

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/*_test.rb']
end

# DOCS ########################################################################

desc "Generate API documentation"
task :api => FileList['lib/**/*.rb'] do |t|
  output_dir = ENV['OUTPUT_DIR'] || 'api'
  rm_rf output_dir
  sh((<<-SH).gsub(/[\s\n]+/, ' ').strip)
  hanna
    --op #{output_dir}
    --promiscuous
    --charset utf8
    --fmt html
    --inline-source
    --line-numbers
    --accessor option_accessor=RW
    --main Rack::Accept
    --title 'Rack::Accept API Documentation'
    #{t.prerequisites.join(' ')}
  SH
end

CLEAN.include 'api'

# PACKAGING & INSTALLATION ####################################################

if defined?(Gem)
  $spec = eval("#{File.read('rack-accept.gemspec')}")

  directory 'dist'

  def package(ext='')
    "dist/#{$spec.name}-#{$spec.version}" + ext
  end

  file package('.gem') => %w< dist > + $spec.files do |f|
    sh "gem build rack-accept.gemspec"
    mv File.basename(f.name), f.name
  end

  file package('.tar.gz') => %w< dist > + $spec.files do |f|
    sh "git archive --format=tar HEAD | gzip > #{f.name}"
  end

  desc "Build packages"
  task :package => %w< .gem .tar.gz >.map {|e| package(e) }

  desc "Build and install as local gem"
  task :install => package('.gem') do |t|
    sh "gem install #{package('.gem')}"
  end

  desc "Upload gem to rubygems.org"
  task :release => package('.gem') do |t|
    sh "gem push #{package('.gem')}"
  end
end

CLOBBER.include 'dist'
