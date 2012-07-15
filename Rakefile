# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rdoc/task'

require 'tasks/rails'
# Load rake tasks from plugins in chiliproject_plugins
Dir["#{RAILS_ROOT}/vendor/chiliproject_plugins/*/lib/tasks/**/*.rake"].sort.each { |ext| load ext }
