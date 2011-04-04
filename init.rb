require 'redmine'
require 'dispatcher'

Dispatcher.to_prepare do
  require_dependency 'project'
  require 'redmine_meeting/patch_redmine_classes'
  Project.send(:include, ::Plugin::Meeting::Project)
  Mailer.send(:include, ::Plugin::Meeting::Mailer)
end

Redmine::Plugin.register :redmine_meeting do
  name 'Redmine Meeting'
  author 'Felix Schäfer @ finnlabs'
  author_url 'http://finn.de/team'
  description 'This plugin adds a meeting module with functionality to plan an agenda and save the minutes of a meeting.'
  url 'http://finn.de'
  version '1.1.1'

  requires_redmine :version_or_higher => '1.0'

  project_module :meetings do
    permission :create_meetings, {:meetings => [:new, :create, :copy]}, :require => :member
    permission :edit_meetings, {:meetings => [:edit, :update]}, :require => :member
    permission :delete_meetings, {:meetings => [:destroy]}, :require => :member
    permission :view_meetings, {:meetings => [:index, :show], :meeting_agendas => [:history, :show, :diff], :meeting_minutes => [:history, :show, :diff]}
    permission :create_meeting_agendas, {:meeting_agendas => [:update, :preview]}, :require => :member
    permission :close_meeting_agendas, {:meeting_agendas => [:close, :open]}, :require => :member
    permission :send_meeting_agendas_notification, {:meeting_agendas => [:notify]}, :require => :member
    permission :create_meeting_minutes, {:meeting_minutes => [:update, :preview]}, :require => :member
    permission :send_meeting_minutes_notification, {:meeting_minutes => [:notify]}, :require => :member
  end

  Redmine::Search.map do |search|
    search.register :meetings
  end

  menu :project_menu, :meetings, {:controller => 'meetings', :action => 'index'}, :caption => :project_module_meetings, :param => :project_id, :after => :wiki
end
