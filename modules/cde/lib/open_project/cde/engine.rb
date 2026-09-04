# frozen_string_literal: true

require 'open_project/plugins'

module OpenProject::Cde
  class Engine < ::Rails::Engine
    engine_name :openproject_cde

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-cde',
             author_url: 'https://www.bimpro.edu',
             bundled: false,
             settings: {
               default: {}
             } do
      project_module(:cde, dependencies: :work_package_tracking) do
        # Container permissions (defined in config/cde_conventions.yml)
        permission :view_wip_container,
                   {
                     'cde/containers' => %i[index show defaults],
                     'cde/containers/published' => %i[index]
                   },
                   permissible_on: :project

        permission :edit_container,
                   { 'cde/containers' => %i[create update edit new] },
                   permissible_on: :project,
                   dependencies: %i[view_wip_container]

        permission :share_container,
                   {},
                   permissible_on: :project,
                   dependencies: %i[view_wip_container]

        permission :approve_container,
                   {},
                   permissible_on: :project,
                   dependencies: %i[view_wip_container]

        permission :publish_container,
                   {},
                   permissible_on: :project,
                   dependencies: %i[approve_container]

        permission :archive_container,
                   {},
                   permissible_on: :project,
                   dependencies: %i[publish_container]

        permission :manage_exchange_packages,
                   {},
                   permissible_on: :project,
                   dependencies: %i[publish_container]

        # API permissions
        permission :read_cde_api,
                   { 'api/v3/cde/containers' => %i[index show] },
                   permissible_on: :project

        permission :write_cde_api,
                   { 'api/v3/cde/containers' => %i[create update destroy] },
                   permissible_on: :project,
                   dependencies: %i[view_wip_container]
      end

      # Mount API routes
      config.to_prepare do
        ::API::Root.class_eval do
          version 'v3', using: :path do
            namespace :cde do
              mount ::API::V3::Cde::ContainersController
            end
          end
        end
      end
    end
  end
end
