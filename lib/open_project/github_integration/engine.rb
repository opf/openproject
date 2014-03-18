# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::GithubIntegration
  class Engine < ::Rails::Engine
    engine_name :openproject_github_integration

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-github_integration',
             :author_url => 'http://finn.de',
             :requires_openproject => '>= 3.0.0pre50',
             :settings => { 'default' => {"github_access_token" => ""},
                            :partial => 'settings/github_settings'}

    OpenProject::Webhooks.register_hook 'github' do |hook, environment, params, user, project|
      OpenProject::GithubIntegration::HookHandler.new.process(hook, environment, params, user, project)
    end

    ActiveSupport::Notifications.subscribe('github.ping') do |name, start, finish, id, payload|
      require 'pry'; binding.pry
      puts "PING!"
    end

    ActiveSupport::Notifications.subscribe('github.pull_request') do |name, start, finish, id, payload|
      require 'pry'; binding.pry
      puts "pull request"
    end
  end
end
