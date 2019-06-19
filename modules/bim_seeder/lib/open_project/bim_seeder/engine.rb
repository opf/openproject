# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::BimSeeder
  class Engine < ::Rails::Engine
    engine_name :bim_seeder

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-bim_seeder',
             :author_url => 'https://openproject.org',
             :requires_openproject => '>= 9.0.0'

    patches [:RootSeeder]
    patch_with_namespace :DemoData, :QueryBuilder
  end
end
