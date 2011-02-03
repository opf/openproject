require 'redmine'
require 'dispatcher'

Dispatcher.to_prepare do
  require_dependency 'project'
  require 'redmine_meeting/patch_redmine_classes'
  Project.send(:include, ::Plugin::Meeting::Project)
end

require_dependency 'redmine_meeting/view_hooks'

Redmine::Plugin.register :redmine_meeting do
  name 'Redmine Meeting'
  author 'Felix Schäfer @ finnlabs'
  author_url 'http://finn.de/team'
  description 'This plugin adds a meeting module with functionality to plan and save the minutes of a meeting.'
  url 'http://finn.de'
  version '0.0.1'
  
  requires_redmine :version_or_higher => '0.9'
  
  project_module :meetings do
    permission :manage_meetings, {:meetings => [:index, :new, :create, :destroy, :show, :edit, :update]}, :require => :member
  end
  
  menu :project_menu, :meetings, {:controller => 'meetings', :action => 'index'}, :caption => :label_meeting_plural, :param => :project_id
  
end
