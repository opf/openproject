require "open_project/plugins"

module OpenProject::TypeSchemes
  class Engine < ::Rails::Engine
    engine_name :openproject_type_schemes

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-type_schemes",
             author_url: "https://www.openproject.org",
             bundled: true
  end
end
