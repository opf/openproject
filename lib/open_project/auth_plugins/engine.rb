# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::AuthPlugins
  class Engine < ::Rails::Engine
    engine_name :openproject_auth_plugins

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-auth_plugins',
             :author_url => 'http://finn.de',
             :requires_openproject => '>= 3.1.0pre1'

    initializer 'auth_plugins.register_hooks' do
      require 'open_project/auth_plugins/hooks'
    end
  end
end
