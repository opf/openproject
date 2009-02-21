require 'rake'
require 'rake/rdoctask'
require 'tmpdir'

task :default => :doc

desc 'Generate documentation for the engines plugin.'
Rake::RDocTask.new(:doc) do |doc|
  doc.rdoc_dir = 'doc'
  doc.title    = 'Engines'
  doc.main     = "README"
  doc.rdoc_files.include("README", "CHANGELOG", "MIT-LICENSE")
  doc.rdoc_files.include('lib/**/*.rb')
  doc.options << '--line-numbers' << '--inline-source'
end

desc 'Run the engine plugin tests within their test harness'
task :cruise do
  # checkout the project into a temporary directory
  version = "rails_2.0"
  test_dir = "#{Dir.tmpdir}/engines_plugin_#{version}_test"
  puts "Checking out test harness for #{version} into #{test_dir}"
  `svn co http://svn.rails-engines.org/test/engines/#{version} #{test_dir}`

  # run all the tests in this project
  Dir.chdir(test_dir)
  load 'Rakefile'
  puts "Running all tests in test harness"
  ['db:migrate', 'test', 'test:plugins'].each do |t|
    Rake::Task[t].invoke
  end  
end

task :clean => [:clobber_doc, "test:clean"]

namespace :test do
  
  # Yields a block with STDOUT and STDERR silenced. If you *really* want
  # to output something, the block is yielded with the original output
  # streams, i.e.
  #
  #   silence do |o, e|
  #     puts 'hello!' # no output produced
  #     o.puts 'hello!' # output on STDOUT
  #   end
  #
  # (based on silence_stream in ActiveSupport.)
  def silence
    yield(STDOUT, STDERR) if ENV['VERBOSE']
    streams = [STDOUT, STDERR]
    actual_stdout = STDOUT.dup
    actual_stderr = STDERR.dup
    streams.each do |s| 
      s.reopen(RUBY_PLATFORM =~ /mswin/ ? 'NUL:' : '/dev/null') 
      s.sync = true
    end
    yield actual_stdout, actual_stderr
  ensure
    STDOUT.reopen(actual_stdout)
    STDERR.reopen(actual_stderr)
  end
  
  def test_app_dir
    File.join(File.dirname(__FILE__), 'test_app')
  end
  
  def run(cmd)
    cmd = cmd.join(" && ") if cmd.is_a?(Array)
    system(cmd) || raise("failed running '#{cmd}'")
  end
  
  desc 'Remove the test application'
  task :clean do
    FileUtils.rm_r(test_app_dir) if File.exist?(test_app_dir)
  end
  
  desc 'Build the test rails application (use RAILS=[edge,<directory>] to test against specific version)'
  task :generate_app do
    silence do |out, err|
      out.puts "> Creating test application at #{test_app_dir}"
        
      if ENV['RAILS']
        vendor_dir = File.join(test_app_dir, 'vendor')
        FileUtils.mkdir_p vendor_dir
        
        if ENV['RAILS'] == 'edge'
          out.puts "    Cloning Edge Rails from GitHub"
          run "cd #{vendor_dir} && git clone --depth 1 git://github.com/rails/rails.git"
        elsif ENV['RAILS'] =~ /\d\.\d\.\d/
          if ENV['CURL']
            out.puts "    Cloning Rails Tag #{ENV['RAILS']} from GitHub using curl and tar"
            run ["cd #{vendor_dir}",
                 "mkdir rails",
                 "cd rails",
                 "curl -s -L http://github.com/rails/rails/tarball/#{ENV['RAILS']} | tar xzv --strip-components 1"]
          else
            out.puts "    Cloning Rails Tag #{ENV['RAILS']} from GitHub (can be slow - set CURL=true to use curl)"
            run ["cd #{vendor_dir}",
                 "git clone git://github.com/rails/rails.git",
                 "cd rails",
                 "git pull",
                 "git checkout v#{ENV['RAILS']}"]
          end
        elsif File.exist?(ENV['RAILS'])
          out.puts "    Linking rails from #{ENV['RAILS']}"
          run "cd #{vendor_dir} && ln -s #{ENV['RAILS']} rails"
        else
          raise "Couldn't build test application from '#{ENV['RAILS']}'"
        end
      
        out.puts "    generating rails default directory structure"
        run "ruby #{File.join(vendor_dir, 'rails', 'railties', 'bin', 'rails')} #{test_app_dir}"
      else
        version = `rails --version`.chomp.split.last
        out.puts "    building rails using the 'rails' command (rails version: #{version})"
        run "rails #{test_app_dir}"
      end
    
      # get the database config and schema in place
      out.puts "    writing database.yml"
      require 'yaml'
      File.open(File.join(test_app_dir, 'config', 'database.yml'), 'w') do |f|
        f.write(%w(development test).inject({}) do |h, env| 
          h[env] = {"adapter" => "sqlite3", "database" => "engines_#{env}.sqlite3"} ; h
        end.to_yaml)
      end
      out.puts "    installing exception_notification plugin"
      run "cd #{test_app_dir} && ./script/plugin install git://github.com/rails/exception_notification.git"
    end
  end
  
  # We can't link the plugin, as it needs to be present for script/generate to find
  # the plugin generator.
  # TODO: find and +1/create issue for loading generators from symlinked plugins
  desc 'Mirror the engines plugin into the test application'
  task :copy_engines_plugin do
    puts "> Copying engines plugin into test application"
    engines_plugin = File.join(test_app_dir, "vendor", "plugins", "engines")
    FileUtils.rm_r(engines_plugin) if File.exist?(engines_plugin)
    FileUtils.mkdir_p(engines_plugin)
    FileList["*"].exclude("test_app").each do |file|
      FileUtils.cp_r(file, engines_plugin)
    end
  end
  
  def insert_line(line, options)
    line = line + "\n"
    target_file = File.join(test_app_dir, options[:into])
    lines = File.readlines(target_file)
    return if lines.include?(line)
    
    if options[:after]
      if options[:after].is_a?(String)
        after_line = options[:after] + "\n"
      else
        after_line = lines.find { |l| l =~ options[:after] }
        raise "couldn't find a line matching #{options[:after].inspect} in #{target_file}" unless after_line
      end
      index = lines.index(after_line)
      raise "couldn't find line '#{after_line}' in #{target_file}" unless index
      lines.insert(index + 1, line)
    else
      lines << line
    end
    File.open(target_file, 'w') { |f| f.write lines.join }
  end
  
  def mirror_test_files(src, dest=nil)
    destination_dir = File.join(*([test_app_dir, dest].compact))
    FileUtils.cp_r(File.join(File.dirname(__FILE__), 'test', src), destination_dir)
  end
  
  desc 'Update the plugin and tests files in the test application from the plugin'
  task :mirror_engine_files => [:test_app, :copy_engines_plugin] do
    puts "> Modifying default config files to load engines plugin"
    insert_line("require File.join(File.dirname(__FILE__), '../vendor/plugins/engines/boot')",
                :into => 'config/environment.rb',
                :after => "require File.join(File.dirname(__FILE__), 'boot')")
                
    insert_line('map.from_plugin :test_routing', :into => 'config/routes.rb', 
                :after => /\AActionController::Routing::Routes/)
                
    insert_line("require 'engines_test_helper'", :into => 'test/test_helper.rb')
    
    puts "> Mirroring test application files into #{test_app_dir}"
    mirror_test_files('app')
    mirror_test_files('lib')
    mirror_test_files('plugins', 'vendor')
    mirror_test_files('unit', 'test')
    mirror_test_files('functional', 'test')
  end
  
  desc 'Prepare the engines test environment'
  task :test_app do
    version_tag = File.join(test_app_dir, 'RAILS_VERSION')
    existing_version = File.read(version_tag).chomp rescue 'unknown'
    if existing_version == ENV['RAILS']
      puts "> Reusing existing test application (#{ENV['RAILS']})"
    else
      puts "> Recreating test application"
      Rake::Task["test:clean"].invoke
      Rake::Task["test:generate_app"].invoke
      
      File.open(version_tag, "w") { |f| f.write ENV['RAILS'] }
    end
  end
end

task :test => "test:mirror_engine_files" do
  puts "> Loading the test application environment and running tests"
  # We use exec here to replace the current running rake process
  exec("cd #{test_app_dir} && rake db:migrate && rake")
end
