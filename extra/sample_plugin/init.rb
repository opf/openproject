# Redmine sample plugin
require 'redmine'

RAILS_DEFAULT_LOGGER.info 'Starting Example plugin for RedMine'

Redmine::Plugin.register :sample_plugin do
  name 'Example plugin'
  author 'Author name'
  description 'This is a sample plugin for Redmine'
  version '0.0.1'
  settings :default => {'sample_setting' => 'value', 'foo'=>'bar'}, :partial => 'settings/settings'

  # This plugin adds a project module
  # It can be enabled/disabled at project level (Project settings -> Modules)
  project_module :example_module do
    # A public action
    permission :example_say_hello, {:example => [:say_hello]}, :public => true
    # This permission has to be explicitly given
    # It will be listed on the permissions screen
    permission :example_say_goodbye, {:example => [:say_goodbye]}
    # This permission can be given to project members only
    permission :view_meetings, {:meetings => [:index, :show]}, :require => :member
  end

  # A new item is added to the project menu
  menu :project_menu, :sample_plugin, { :controller => 'example', :action => 'say_hello' }, :caption => 'Sample'
  
  # Meetings are added to the activity view
  activity_provider :meetings
end
