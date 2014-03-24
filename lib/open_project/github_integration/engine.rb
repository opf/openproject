# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'
# require 'open_project/notifications'

module OpenProject::GithubIntegration
  class Engine < ::Rails::Engine
    engine_name :openproject_github_integration

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-github_integration',
             :author_url => 'http://finn.de',
             :requires_openproject => '>= 3.1.0pre1'


    initializer 'github_integration.register_hook' do
      ::OpenProject::Webhooks.register_hook 'github' do |hook, environment, params, user|
        HookHandler.new.process(hook, environment, params, user)
      end
    end

    initializer 'github_integration.subscribe_to_notifications' do
      ::OpenProject::Notifications.subscribe('github.ping',
                                             &NotificationHandlers.method(:ping))

      ::OpenProject::Notifications.subscribe('github.pull_request',
                                             &NotificationHandlers.method(:pull_request))
    end

  end
end
