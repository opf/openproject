#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'open_project/plugins'

module OpenProject::Bim
  class Engine < ::Rails::Engine
    engine_name :openproject_bim

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-bim',
             author_url: 'https://openproject.com',
             settings: {
               default: {
               }
             } do
      project_module(:bim,
                     if: ->(*) { OpenProject::Configuration.bim? }) do
        permission :view_ifc_models,
                   {'bim/ifc_models/ifc_models': %i[index show defaults]}
        permission :manage_ifc_models,
                   {'bim/ifc_models/ifc_models': %i[index show destroy edit update create new]},
                   dependencies: %i[view_ifc_models]

        permission :view_linked_issues,
                   {'bim/bcf/issues': %i[index]},
                   dependencies: %i[view_work_packages]
        permission :manage_bcf,
                   {'bim/bcf/issues': %i[index upload prepare_import configure_import perform_import]},
                   dependencies: %i[view_linked_issues
                                    view_work_packages
                                    add_work_packages
                                    edit_work_packages
                                    delete_work_packages]
      end

      OpenProject::AccessControl.permission(:view_work_packages).actions << 'bim/bcf/issues/redirect_to_bcf_issues_list'

      ::Redmine::MenuManager.map(:project_menu) do |menu|
        menu.push(:ifc_models,
                  { controller: '/bim/ifc_models/ifc_models', action: 'defaults' },
                  caption: :'bim.label_bim',
                  param: :project_id,
                  after: :work_packages,
                  icon: 'icon2 icon-ifc',
                  badge: :label_new)

        menu.push :ifc_viewer_panels,
                  { controller: '/bim/ifc_models/ifc_models', action: 'defaults' },
                  param: :project_id,
                  parent: :ifc_models,
                  partial: '/bim/ifc_models/ifc_models/panels'
      end
    end

    class_inflection_override('v2_1' => 'V2_1')

    assets %w(bim/bcf.css bim/ifc_viewer/generic.css)

    patches %i[WorkPackage Type Journal RootSeeder Project]

    patch_with_namespace :OpenProject, :CustomStyles, :Design
    patch_with_namespace :BasicData, :SettingSeeder
    patch_with_namespace :BasicData, :RoleSeeder
    patch_with_namespace :API, :V3, :Activities, :ActivityRepresenter
    patch_with_namespace :Journal, :AggregatedJournal
    patch_with_namespace :API, :V3, :Activities, :ActivitiesSharedHelpers

    patch_with_namespace :DemoData, :QueryBuilder
    patch_with_namespace :DemoData, :ProjectSeeder
    patch_with_namespace :DemoData, :WorkPackageSeeder
    patch_with_namespace :DemoData, :WorkPackageBoardSeeder

    extend_api_response(:v3, :work_packages, :work_package) do
      property :bcf,
               exec_context: :decorator,
               getter: ->(*) {
                 issue = represented.bcf_issue
                 bcf = {}
                 bcf[:uuid] = issue.uuid
                 bcf[:viewpoints] = issue.viewpoints.map do |viewpoint|
                   {
                     uuid: viewpoint.uuid,
                     snapshot_id: viewpoint.snapshot.id,
                     snapshot_file_name: viewpoint.snapshot.filename
                   }
                 end
                 bcf
               },
               if: ->(*) {
                 represented.bcf_issue.present?
               }
    end

    extend_api_response(:v3, :work_packages, :work_package_collection) do
      require_relative 'patches/api/v3/export_formats'

      prepend Patches::API::V3::ExportFormats
    end

    extend_api_response(:v3, :work_packages, :schema, :work_package_schema) do
      schema :bcf_thumbnail,
             type: 'BCF Thumbnail',
             required: false,
             writable: false,
             show_if: ->(*) { represented&.project&.module_enabled?(:bcf) }
    end

    extend_api_response(:v3, :activities, :activity) do
      property :bcf_comment,
               exec_context: :decorator,
               getter: ->(*) {
                 bcf_comment = represented.bcf_comment
                 comment = {
                   id: bcf_comment.id
                 }
                 if bcf_comment.viewpoint.present?
                   comment[:viewpoint] = {
                     snapshot: {
                       id: bcf_comment.viewpoint.snapshot.id,
                       file_name: bcf_comment.viewpoint.snapshot.filename
                     }
                   }
                 end

                 comment
               },
               if: ->(*) {
                 represented.bcf_comment.present?
               }
    end

    add_api_path :bcf_xml do |project_id|
      "#{project(project_id)}/bcf_xml"
    end

    config.to_prepare do
      require_relative 'hooks'
    end

    initializer 'bim.bcf.register_hooks' do
      # don't use require_dependency to not reload hooks in development mode
      require 'open_project/xls_export/hooks/work_package_hook.rb'
    end

    initializer 'bim.bcf.register_mimetypes' do
      Mime::Type.register "application/octet-stream", :bcf unless Mime::Type.lookup_by_extension(:bcf)
      Mime::Type.register "application/octet-stream", :bcfzip unless Mime::Type.lookup_by_extension(:bcfzip)
    end

    initializer 'bim.bcf.add_api_scope' do
      Doorkeeper.configuration.scopes.add(:bcf_v2_1)

      module OpenProject::Authentication::Scope
        BCF_V2_1 = :bcf_v2_1
      end

      OpenProject::Authentication.update_strategies(OpenProject::Authentication::Scope::BCF_V2_1,
                                                    store: false) do |_strategies|
        %i[oauth session]
      end
    end

    config.to_prepare do
      ::WorkPackage::Exporter
        .register_for_list(:bcf, OpenProject::Bim::BcfXml::Exporter)

      ::Queries::Register.filter ::Query, OpenProject::Bim::BcfIssueAssociatedFilter
      ::Queries::Register.column ::Query, OpenProject::Bim::QueryBcfThumbnailColumn

      ::API::Root.class_eval do
        content_type :binary, 'application/octet-stream'
        default_format :binary
        version 'v1', using: :path do
          mount ::API::Bim::BcfXml::V1::BcfXmlAPI
        end
      end
    end
  end
end
