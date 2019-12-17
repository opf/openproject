#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'open_project/plugins'

module OpenProject::Bcf
  class Engine < ::Rails::Engine
    engine_name :openproject_bcf

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-bcf',
             author_url: 'https://openproject.com',
             settings: {
               default: {
               }
             } do
      project_module :bcf do
        permission :view_linked_issues,
                   { 'bcf/issues': %i[index] },
                   dependencies: %i[view_work_packages]
        permission :manage_bcf,
                   { 'bcf/issues': %i[index upload prepare_import configure_import perform_import] },
                   dependencies: %i[view_linked_issues
                                    view_work_packages
                                    add_work_packages
                                    edit_work_packages
                                    delete_work_packages]
      end

      OpenProject::AccessControl.permission(:view_work_packages).actions << 'bcf/issues/redirect_to_bcf_issues_list'

      rename_menu_item :project_menu,
                       :work_packages,
                       { url: Proc.new { |project| project.module_enabled?(:bcf) ?
                                                     { controller: 'bcf/issues', action: 'redirect_to_bcf_issues_list' } :
                                                     { controller: '/work_packages', action: 'index' } },
                         caption: Proc.new { |project| project.module_enabled?(:bcf) ? I18n.t(:'bcf.label_bcf') : I18n.t(:label_work_package_plural) },
                         icon: Proc.new { |project| project.module_enabled?(:bcf) ? 'icon2 icon-bcf' : 'icon2 icon-view-timeline' },
                         badge: Proc.new { |project| project.module_enabled?(:bcf) ? 'bcf.new_badge' : nil } }

    end

    assets %w(bcf/bcf.css)

    patches %i[WorkPackage Type Journal]

    patch_with_namespace :BasicData, :SettingSeeder
    patch_with_namespace :BasicData, :RoleSeeder
    patch_with_namespace :API, :V3, :Activities, :ActivityRepresenter
    patch_with_namespace :Journal, :AggregatedJournal
    patch_with_namespace :API, :V3, :Activities, :ActivitiesSharedHelpers

    extend_api_response(:v3, :work_packages, :work_package) do
      property :bcf,
               exec_context: :decorator,
               getter: ->(*) {
                 issue = represented.bcf_issue
                 bcf = {}
                 bcf[:viewpoints] = issue.viewpoints.map do |viewpoint|
                   {
                     id: viewpoint.snapshot.id,
                     file_name: viewpoint.snapshot.filename
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

      prepend Patches::Api::V3::ExportFormats
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

    initializer 'bcf.register_hooks' do
      # don't use require_dependency to not reload hooks in development mode
      require 'open_project/xls_export/hooks/work_package_hook.rb'
    end

    initializer 'bcf.register_mimetypes' do
      Mime::Type.register "application/octet-stream", :bcf unless Mime::Type.lookup_by_extension(:bcf)
      Mime::Type.register "application/octet-stream", :bcfzip unless Mime::Type.lookup_by_extension(:bcfzip)
    end

    initializer 'bcf.add_api_scope' do
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
        .register_for_list(:bcf, OpenProject::Bcf::BcfXml::Exporter)

      ::Queries::Register.filter ::Query, OpenProject::Bcf::BcfIssueAssociatedFilter
      ::Queries::Register.column ::Query, OpenProject::Bcf::QueryBcfThumbnailColumn

      ::API::Root.class_eval do
        content_type :binary, 'application/octet-stream'
        default_format :binary
        version 'v1', using: :path do
          mount ::API::BcfXml::V1::BcfXmlAPI
        end
      end
    end
  end
end
