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
    module Versions
      class VersionRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::Decorators::DateProperty
        include API::Decorators::FormattableProperty
        include ::API::Caching::CachedRepresenter
        extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass

        cached_representer key_parts: %i(project)

        self_link

        link :schema do
          {
            href: api_v3_paths.version_schema
          }
        end

        link :update,
             cache_if: -> { current_user.allowed_in_project?(:manage_versions, represented.project) } do
          {
            href: api_v3_paths.version_form(represented.id),
            method: :post
          }
        end

        link :updateImmediately,
             cache_if: -> { current_user.allowed_in_project?(:manage_versions, represented.project) } do
          {
            href: api_v3_paths.version(represented.id),
            method: :patch
          }
        end

        link :delete,
             cache_if: -> { current_user.allowed_in_project?(:manage_versions, represented.project) } do
          {
            href: api_v3_paths.version(represented.id),
            method: :delete
          }
        end

        associated_resource :project,
                            as: :definingProject,
                            skip_render: ->(*) { !represented.project || !represented.project.visible?(current_user) }

        link :availableInProjects do
          {
            href: api_v3_paths.projects_by_version(represented.id)
          }
        end

        property :id,
                 render_nil: true

        property :name,
                 render_nil: true

        formattable_property :description,
                             plain: true

        date_property :start_date

        date_property :effective_date,
                      as: "endDate",
                      writable: true

        property :status

        property :sharing

        date_time_property :created_at
        date_time_property :updated_at

        def _type
          "Version"
        end
      end
    end
  end
end
