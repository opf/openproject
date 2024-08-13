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

require "roar/decorator"
require "roar/json/hal"

module API
  module V3
    module Projects
      class ProjectRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::Decorators::DateProperty
        include ::API::Caching::CachedRepresenter
        include API::Decorators::FormattableProperty
        extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass

        def self.current_user_view_allowed_lambda
          ->(*) { current_user.allowed_in_project?(:view_project, represented) || current_user.allowed_globally?(:add_project) }
        end

        custom_field_injector cache_if: current_user_view_allowed_lambda

        cached_representer disabled: false

        self_link

        link :createWorkPackage,
             cache_if: -> { current_user.allowed_in_project?(:add_work_packages, represented) } do
          {
            href: api_v3_paths.create_project_work_package_form(represented.id),
            method: :post
          }
        end

        link :createWorkPackageImmediately,
             cache_if: -> { current_user.allowed_in_project?(:add_work_packages, represented) } do
          {
            href: api_v3_paths.work_packages_by_project(represented.id),
            method: :post
          }
        end

        link :workPackages,
             cache_if: -> {
               current_user.allowed_in_project?(:view_work_packages, represented)
             } do
          { href: api_v3_paths.work_packages_by_project(represented.id) }
        end

        links :storages,
              cache_if: -> {
                current_user.allowed_in_project?(:view_file_links, represented)
              } do
          represented.storages.map do |storage|
            {
              href: api_v3_paths.storage(storage.id),
              title: storage.name
            }
          end
        end

        link :categories do
          { href: api_v3_paths.categories_by_project(represented.id) }
        end

        link :versions,
             cache_if: -> {
               current_user.allowed_in_project?(:view_work_packages, represented) ||
               current_user.allowed_in_project?(:manage_versions, represented)
             } do
          { href: api_v3_paths.versions_by_project(represented.id) }
        end

        link :memberships,
             cache_if: -> {
               current_user.allowed_in_project?(:view_members, represented)
             } do
          {
            href: api_v3_paths.path_for(:memberships, filters: [{ project: { operator: "=", values: [represented.id.to_s] } }])
          }
        end

        link :types,
             cache_if: -> {
               current_user.allowed_in_project?(:view_work_packages, represented) ||
               current_user.allowed_in_project?(:manage_types, represented)
             } do
          { href: api_v3_paths.types_by_project(represented.id) }
        end

        link :update,
             cache_if: -> {
               current_user.allowed_in_project?(:edit_project, represented)
             } do
          {
            href: api_v3_paths.project_form(represented.id),
            method: :post
          }
        end

        link :updateImmediately,
             cache_if: -> {
               current_user.allowed_in_project?(:edit_project, represented)
             } do
          {
            href: api_v3_paths.project(represented.id),
            method: :patch
          }
        end

        link :delete,
             cache_if: -> { current_user.admin? } do
          {
            href: api_v3_paths.project(represented.id),
            method: :delete
          }
        end

        link :schema do
          {
            href: api_v3_paths.projects_schema
          }
        end

        links :ancestors,
              uncacheable: true do
          represented.ancestors_from_root.map do |ancestor|
            # Explicitly check for admin as an archived project
            # will lead to the admin losing permissions in the project.
            if current_user.admin? || ancestor.visible?
              {
                href: api_v3_paths.project(ancestor.id),
                title: ancestor.name
              }
            else
              {
                href: API::V3::URN_UNDISCLOSED,
                title: I18n.t(:"api_v3.undisclosed.ancestor")
              }
            end
          end
        end

        link :projectStorages, uncacheable: true do
          filters = [{ projectId: { operator: "=", values: [represented.id.to_s] } }]
          { href: api_v3_paths.path_for(:project_storages, filters:) }
        end

        associated_resource :parent,
                            v3_path: :project,
                            representer: ::API::V3::Projects::ProjectRepresenter,
                            uncacheable_link: true,
                            undisclosed: true,
                            skip_render: ->(*) { represented.parent && !represented.parent.visible? && !current_user.admin? }

        property :id
        property :identifier,
                 render_nil: true

        property :name,
                 render_nil: true

        property :active
        property :public

        formattable_property :description,
                             cache_if: current_user_view_allowed_lambda

        date_time_property :created_at

        date_time_property :updated_at

        resource :status,
                 skip_render: ->(*) {
                   !current_user.allowed_in_project?(:view_project, represented) &&
                     !current_user.allowed_globally?(:add_project)
                 },
                 link_cache_if: current_user_view_allowed_lambda,
                 getter: ->(*) {
                           next unless represented.status_code

                           ::API::V3::Projects::Statuses::StatusRepresenter
                             .create(represented.status_code, current_user:, embed_links:)
                         },
                 link: ->(*) {
                         if represented.status_code
                           {
                             href: api_v3_paths.project_status(represented.status_code),
                             title: I18n.t(:"activerecord.attributes.project.status_codes.#{represented.status_code}",
                                           default: nil)
                           }.compact
                         else
                           {
                             href: nil
                           }
                         end
                       },
                 setter: ->(fragment:, represented:, **) {
                           link = ::API::Decorators::LinkObject.new(represented,
                                                                    path: :project_status,
                                                                    property_name: :status_code,
                                                                    setter: :"status_code=")
                           link.from_hash(fragment)
                         }

        formattable_property :status_explanation,
                             cache_if: current_user_view_allowed_lambda

        def _type
          "Project"
        end

        self.to_eager_load = [:enabled_modules]

        self.checked_permissions = %i[add_work_packages view_project]
      end
    end
  end
end
