#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "open_project/plugins"

module OpenProject::Bim
  class Engine < ::Rails::Engine
    engine_name :openproject_bim

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-bim",
             author_url: "https://www.openproject.org",
             bundled: true,
             settings: {
               default: {}
             } do
      project_module(:bim,
                     dependencies: :work_package_tracking,
                     if: ->(*) { OpenProject::Configuration.bim? }) do
        permission :view_ifc_models,
                   {
                     "bim/ifc_models/ifc_models": %i[index show defaults],
                     "bim/ifc_models/ifc_viewer": %i[show],
                     "bim/menus": %i[show]
                   },
                   permissible_on: :project,
                   contract_actions: { ifc_models: %i[read] }
        permission :manage_ifc_models,
                   { "bim/ifc_models/ifc_models": %i[index show destroy edit update create new] },
                   permissible_on: :project,
                   dependencies: %i[view_ifc_models],
                   contract_actions: { ifc_models: %i[create update destroy] }
        permission :view_linked_issues,
                   { "bim/bcf/issues": %i[index] },
                   permissible_on: :project,
                   dependencies: %i[view_work_packages],
                   contract_actions: { bcf: %i[read] }
        permission :manage_bcf,
                   { "bim/bcf/issues": %i[index upload prepare_import configure_import perform_import] },
                   permissible_on: :project,
                   dependencies: %i[view_linked_issues
                                    view_work_packages
                                    add_work_packages
                                    edit_work_packages],
                   contract_actions: { bcf: %i[create update] }
        permission :delete_bcf,
                   {},
                   permissible_on: :project,
                   dependencies: %i[view_linked_issues
                                    manage_bcf
                                    view_work_packages
                                    add_work_packages
                                    edit_work_packages
                                    delete_work_packages],
                   contract_actions: { bcf: %i[destroy] }
        permission :save_bcf_queries,
                   {},
                   permissible_on: :project,
                   dependencies: %i[save_queries]
        permission :manage_public_bcf_queries,
                   {},
                   permissible_on: :project,
                   dependencies: %i[manage_public_queries save_bcf_queries]
      end

      Rails.application.reloader.to_prepare do
        OpenProject::AccessControl
          .permission(:view_work_packages)
          .controller_actions << "bim/bcf/issues/redirect_to_bcf_issues_list"
      end

      ::Redmine::MenuManager.map(:project_menu) do |menu|
        menu.push(:ifc_models,
                  { controller: "/bim/ifc_models/ifc_models", action: "defaults" },
                  caption: :"bcf.label_bcf",
                  after: :work_packages,
                  icon: "op-bcf",
                  badge: :label_new)

        menu.push :ifc_viewer_panels,
                  { controller: "/bim/ifc_models/ifc_models", action: "defaults" },
                  parent: :ifc_models,
                  partial: "/bim/menus/menu"
      end
    end

    class_inflection_override("v2_1" => "V2_1")

    assets %w(bim/logo_openproject_bim_big.png bim/logo_openproject_bim_big_coloured.png)

    patches %i[Attachment WorkPackage Type Journal RootSeeder Project FogFileUploader]

    patch_with_namespace :OpenProject, :CustomStyles, :ColorThemes
    patch_with_namespace :API, :V3, :Activities, :ActivityRepresenter
    patch_with_namespace :API, :V3, :WorkPackages, :EagerLoading, :Checksum

    patch_with_namespace :DemoData, :QueryBuilder
    patch_with_namespace :DemoData, :ProjectSeeder
    patch_with_namespace :DemoData, :WorkPackageSeeder
    patch_with_namespace :DemoData, :WorkPackageBoardSeeder

    extend_api_response(:v3, :work_packages, :work_package) do
      include API::Bim::Utilities::PathHelper

      link :bcfTopic,
           cache_if: -> { current_user.allowed_in_project?(:view_linked_issues, represented.project) } do
        next unless represented.bcf_issue?

        {
          href: bcf_v2_1_paths.topic(represented.project.identifier, represented.bcf_issue.uuid)
        }
      end

      link :convertBCF,
           cache_if: -> { current_user.allowed_in_project?(:manage_bcf, represented.project) } do
        next if represented.bcf_issue? || represented.project.nil?

        {
          href: bcf_v2_1_paths.topics(represented.project.identifier),
          title: "Convert to BCF",
          payload: { reference_links: [api_v3_paths.work_package(represented.id)] },
          method: :post
        }
      end

      links :bcfViewpoints,
            cache_if: -> { current_user.allowed_in_project?(:view_linked_issues, represented.project) } do
        next unless represented.bcf_issue?

        represented.bcf_issue.viewpoints.map do |viewpoint|
          {
            href: bcf_v2_1_paths.viewpoint(represented.project.identifier, represented.bcf_issue.uuid, viewpoint.uuid)
          }
        end
      end
    end

    extend_api_response(:v3, :work_packages, :work_package_collection) do
      require_relative "patches/api/v3/export_formats"

      prepend Patches::API::V3::ExportFormats
    end

    extend_api_response(:v3, :work_packages, :schema, :work_package_schema) do
      schema :bcf_thumbnail,
             type: "BCF Thumbnail",
             required: false,
             writable: false,
             show_if: ->(*) { represented&.project&.module_enabled?(:bim) }
    end

    extend_api_response(:v3, :activities, :activity) do
      include API::Bim::Utilities::PathHelper

      links :bcfViewpoints do
        journable = represented.journable
        next unless current_user.allowed_in_project?(:view_linked_issues, represented.project) &&
          represented.bcf_comment.present? && journable.bcf_issue?

        # There will only be one viewpoint per comment but we nevertheless return a collection here so that it is more
        # similar to the work package representer.
        Array(represented.bcf_comment.viewpoint).map do |viewpoint|
          {
            href: bcf_v2_1_paths.viewpoint(journable.project.identifier,
                                           journable.bcf_issue.uuid,
                                           viewpoint.uuid)
          }
        end
      end
    end

    add_api_path :bcf_xml do |project_id|
      "#{project(project_id)}/bcf_xml"
    end

    config.to_prepare do
      OpenProject::Bim::Hooks::Hook
    end

    initializer "bim.bcf.register_mimetypes" do
      Mime::Type.register "application/octet-stream", :bcf unless Mime::Type.lookup_by_extension(:bcf)
      Mime::Type.register "application/octet-stream", :bcfzip unless Mime::Type.lookup_by_extension(:bcfzip)
    end

    config.to_prepare do
      Doorkeeper.configuration.scopes.add(:bcf_v2_1)

      unless defined? OpenProject::Authentication::Scope::BCF_V2_1
        OpenProject::Authentication::Scope::BCF_V2_1 = :bcf_v2_1
      end

      OpenProject::Authentication.update_strategies(OpenProject::Authentication::Scope::BCF_V2_1,
                                                    store: false) do |_strategies|
        %i[oauth session]
      end
    end
    config.to_prepare do
      ::Exports::Register.register do
        list ::WorkPackage, OpenProject::Bim::BcfXml::Exporter
        formatter ::WorkPackage, OpenProject::Bim::WorkPackage::Exporter::Formatters::BcfThumbnail
      end

      ::Queries::Register.register(::Query) do
        filter ::Bim::Queries::WorkPackages::Filter::BcfIssueAssociatedFilter

        select ::Bim::Queries::WorkPackages::Selects::BcfThumbnailSelect
      end

      ::API::Root.class_eval do
        content_type :binary, "application/octet-stream"
        default_format :binary
        version "v1", using: :path do
          mount ::API::Bim::BcfXml::V1::BcfXmlAPI
        end
      end
    end

    add_view :Bim,
             contract_strategy: "Bim::Views::ContractStrategy"
  end
end
