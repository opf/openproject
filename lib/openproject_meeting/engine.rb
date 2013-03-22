require 'rails/engine'

module MeetingsPlugin
  class Engine < ::Rails::Engine
    isolate_namespace MeetingsPlugin

    initializer 'openproject_meeting.precompile_assets' do
      Rails.application.config.assets.precompile += ["openproject_meeting.css"]
    end

    config.to_prepare do
      # This is required for the routes to be loaded first
      # as the routes should be prepended so they take precedence over the core.
      # This mechanism is a preliminary.
      # The core should provide an api to do just that.
      # Unfortunately this implementation here leads to duplicate entries when
      # calling "rake routes". The tasks seems to load the routes twice. Based on the
      # observations made prior to adding this statement, this seems to be limited to
      # "rake routes". The reason for this assumption is that without the statement "rails s" would
      # not load the routes but "rake routes" would.
      require File.join(File.dirname(__FILE__), "/../../config/routes.rb")

      require 'redmine/plugin'

      require_dependency 'openproject_meeting/hooks'
      require 'openproject_meeting/patches/project_patch'
      Project.send(:include, Patches::ProjectPatch)

      # load classes so that all User.before_destroy filters are loaded
      require_dependency 'meeting'
      require_dependency 'meeting_agenda'
      require_dependency 'meeting_minutes'
      require_dependency 'meeting_participant'

      spec = Bundler.environment.specs['openproject_meeting'][0]

      unless Redmine::Plugin.registered_plugins.include?(:redmine_meeting)
        Redmine::Plugin.register :redmine_meeting do
          name 'OpenProject Meeting Plugin'
          author ((spec.authors.kind_of? Array) ? spec.authors[0] : spec.authors)
          author_url spec.homepage
          description spec.description
          version spec.version

          # This plugin actually requires chiliproject 2.0 or higher…
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

          activity_provider :meetings, :default => false, :class_name => ['Meeting', 'MeetingAgenda', 'MeetingMinutes']

          menu :project_menu, :meetings, {:controller => 'meetings', :action => 'index'}, :caption => :project_module_meetings, :param => :project_id, :after => :wiki
          menu :project_menu, :new_meeting, {:controller => 'meetings', :action => 'new'}, :param => :project_id, :caption => :label_meeting_new, :parent => :meetings

          ActiveSupport::Inflector.inflections do |inflect|
            inflect.uncountable "meeting_minutes"
          end
        end
      end
    end
  end
end
