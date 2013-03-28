#  This task will run all plugin specs separated by plugin.
#  A plugin must register for tests via config variable 'plugins_to_test_paths'
#
#  e.g.
#  class Engine < ::Rails::Engine
#    initializer 'register_path_to_rspec' do |app|
#      app.config.plugins_to_test_paths << self.root
#    end
#  end
#

desc "Run plugin tests"
namespace :openproject do
  namespace :plugins do
    namespace :test do
      desc "Run specs for all test registered plugins"
      task :rspec => :environment do
        get_plugins_to_test.each do |plugin_path|
          puts "run specs for #{plugin_path.split('/').last} plugin"
          ENV['SPEC'] = "#{plugin_path}/spec/"
          Rake::Task["spec"].execute
        end
      end
    end
  end
end

def get_plugins_to_test
  plugin_paths = []
  Rails.application.config.plugins_to_test_paths.each do |dir|
    if File.directory?( dir )
      plugin_paths << File.join(dir).to_s
    end
  end
  plugin_paths
end
