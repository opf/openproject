#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module Projects
      class ProjectRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::Decorators::DateProperty
        include ::API::Caching::CachedRepresenter
        include API::Decorators::FormattableProperty
        extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass

        cached_representer key_parts: %i(status),
                           disabled: false

        self_link

        def from_hash(body)
          # Representable is broken when passing nil as parameters
          # it will set the property :status and :statusExplanation
          # regardless of what the setter actually does
          # Bug opened at https://github.com/trailblazer/representable/issues/234
          super(body).tap do |struct|
            next unless struct.respond_to?(:status_attributes)

            # Set the status attribute properly
            struct.status = struct.status_attributes

            # Remove temporary attributes workaround
            struct.delete_field(:status_attributes)

            # Remove nil status_explanation when passed as nil
            if struct.respond_to?(:status_explanation)
              struct.delete_field(:status_explanation)
            end
          end
        end

        link :createWorkPackage,
             cache_if: -> { current_user_allowed_to(:add_work_packages, context: represented) } do
          {
            href: api_v3_paths.create_project_work_package_form(represented.id),
            method: :post
          }
        end

        link :createWorkPackageImmediately,
             cache_if: -> { current_user_allowed_to(:add_work_packages, context: represented) } do
          {
            href: api_v3_paths.work_packages_by_project(represented.id),
            method: :post
          }
        end

        link :workPackages,
             cache_if: -> {
               current_user_allowed_to(:view_work_packages, context: represented)
             } do
          { href: api_v3_paths.work_packages_by_project(represented.id) }
        end

        link :categories do
          { href: api_v3_paths.categories_by_project(represented.id) }
        end

        link :versions,
             cache_if: -> {
               current_user_allowed_to(:view_work_packages, context: represented) ||
                 current_user_allowed_to(:manage_versions, context: represented)
             } do
          { href: api_v3_paths.versions_by_project(represented.id) }
        end

        link :memberships,
             cache_if: -> {
               current_user_allowed_to(:view_members, context: represented)
             } do
          {
            href: api_v3_paths.path_for(:memberships, filters: [{ project: { operator: "=", values: [represented.id.to_s] } }])
          }
        end

        link :types,
             cache_if: -> {
               current_user_allowed_to(:view_work_packages, context: represented) ||
                 current_user_allowed_to(:manage_types, context: represented)
             } do
          { href: api_v3_paths.types_by_project(represented.id) }
        end

        link :update,
             cache_if: -> {
               current_user_allowed_to(:edit_project, context: represented)
             } do
          {
            href: api_v3_paths.project_form(represented.id),
            method: :post
          }
        end

        link :updateImmediately,
             cache_if: -> {
               current_user_allowed_to(:edit_project, context: represented)
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

        associated_resource :parent,
                            v3_path: :project,
                            representer: ::API::V3::Projects::ProjectRepresenter,
                            uncacheable_link: true,
                            undisclosed: true,
                            skip_render: ->(*) { represented.parent && !represented.parent.visible? }

        property :id
        property :identifier,
                 render_nil: true

        property :name,
                 render_nil: true

        property :active
        property :public

        formattable_property :description

        date_time_property :created_at

        date_time_property :updated_at

        resource :status,
                 getter: ->(*) {
                   next unless represented.status&.code

                   ::API::V3::Projects::Statuses::StatusRepresenter
                     .create(represented.status.code, current_user: current_user, embed_links: embed_links)
                 },
                 link: ->(*) {
                   if represented.status&.code
                     {
                       href: api_v3_paths.project_status(represented.status.code),
                       title: I18n.t(:"activerecord.attributes.projects/status.codes.#{represented.status.code}",
                                     default: nil)
                     }.compact
                   else
                     {
                       href: nil
                     }
                   end
                 },
                 setter: ->(fragment:, represented:, **) {
                   represented.status_attributes ||= OpenStruct.new

                   link = ::API::Decorators::LinkObject.new(represented.status_attributes,
                                                            path: :project_status,
                                                            property_name: :status,
                                                            getter: :code,
                                                            setter: :"code=")

                   link.from_hash(fragment)
                 }

        property :status_explanation,
                 writeable: -> { represented.writable?(:status) },
                 getter: ->(*) {
                   ::API::Decorators::Formattable.new(status&.explanation,
                                                      object: self,
                                                      plain: false)
                 },
                 setter: ->(fragment:, represented:, **) {
                   represented.status_attributes ||= OpenStruct.new
                   represented.status_attributes[:explanation] = fragment["raw"]
                 }

        def _type
          'Project'
        end

        self.to_eager_load = [:status,
                              :parent,
                              :enabled_modules,
                              { custom_values: :custom_field }]

        self.checked_permissions = [:add_work_packages]
      end
    end
  end
end
