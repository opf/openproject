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
                   'bcf/issues': :index

        permission :manage_bcf,
                   'bcf/issues': %i[index upload prepare_import configure_import perform_import]
      end

      menu :project_menu,
           :bcf,
           { controller: '/bcf/issues', action: :index },
           caption: :'bcf.label_bcf',
           param: :project_id,
           icon: 'icon2 icon-backlogs',
           badge: 'bcf.experimental_badge'
    end

    assets %w(bcf/bcf.css)

    patches %i[WorkPackage Type]

    patch_with_namespace :BasicData, :SettingSeeder

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

    add_api_path :bcf_xml do |project_id|
      "#{project(project_id)}/bcf_xml"
    end

    add_api_endpoint 'API::V3::Projects::ProjectsAPI' do
      content_type :binary, 'application/octet-stream'
      mount ::API::V3::BcfXml::BcfXmlAPI
    end

    initializer 'bcf.register_hooks' do
      # don't use require_dependency to not reload hooks in development mode
      require 'open_project/xls_export/hooks/work_package_hook.rb'
    end

    initializer 'bcf.register_mimetypes' do
      Mime::Type.register "application/octet-stream", :bcf unless Mime::Type.lookup_by_extension(:bcf)
    end

    config.to_prepare do
      ::WorkPackage::Exporter
        .register_for_list(:bcf, OpenProject::Bcf::BcfXml::Exporter)

      ::Queries::Register.filter ::Query, OpenProject::Bcf::BcfIssueAssociatedFilter
      ::Queries::Register.column ::Query, OpenProject::Bcf::QueryBcfThumbnailColumn
    end
  end
end
