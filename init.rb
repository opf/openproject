require 'redmine'
require 'dispatcher'

Dispatcher.to_prepare do
  require_dependency 'project'
  require 'redmine_meeting/patch_redmine_classes'
  Project.send(:include, ::Plugin::Meeting::Project)
end

Redmine::Plugin.register :redmine_meeting do
  name 'Redmine Meeting'
  author 'Felix Schäfer @ finnlabs'
  author_url 'http://finn.de/team'
  description 'This plugin adds a meeting module with functionality to plan and save the minutes of a meeting.'
  url 'http://finn.de'
  version '0.0.1'

  requires_redmine :version_or_higher => '0.9'

  project_module :meetings do
    permission :create_meetings, {:meetings => [:new, :create]}, :require => :member
    permission :edit_meetings, {:meetings => [:edit, :update]}, :require => :member
    permission :delete_meetings, {:meetings => [:destroy]}, :require => :member
    permission :view_meetings, {:meetings => [:index, :show], :meeting_agendas => [:history, :show, :diff], :meeting_minutes => [:history, :show, :diff]}
    permission :create_meeting_agendas, {:meeting_agendas => [:update]}, :require => :member
    permission :create_meeting_minutes, {:meeting_minutes => [:update]}, :require => :member
  end

  menu :project_menu, :meetings, {:controller => 'meetings', :action => 'index'}, :caption => :project_module_meetings, :param => :project_id

end
