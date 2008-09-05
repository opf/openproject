require 'rails_generator/base'
require 'rails_generator/generators/components/controller/controller_generator'

class RedminePluginControllerGenerator < ControllerGenerator
  attr_reader :plugin_path, :plugin_name, :plugin_pretty_name
  
  def initialize(runtime_args, runtime_options = {})
    runtime_args = runtime_args.dup
    @plugin_name = "redmine_" + runtime_args.shift.underscore
    @plugin_pretty_name = plugin_name.titleize
    @plugin_path = "vendor/plugins/#{plugin_name}"
    super(runtime_args, runtime_options)
  end
  
  def destination_root
    File.join(RAILS_ROOT, plugin_path)
  end
end
