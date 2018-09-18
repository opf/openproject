#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module Projects
      class ProjectRepresenter < ::API::Decorators::Single
        include ::API::Caching::CachedRepresenter

        self_link

        link :createWorkPackage,
             cache_if: -> { current_user_allowed_to(:add_work_packages, context: represented) } do
          {
            href: api_v3_paths.create_project_work_package_form(represented.id),
            method: :post
          }
        end

        link :createWorkPackageImmediate,
             cache_if: -> { current_user_allowed_to(:add_work_packages, context: represented) } do
          {
            href: api_v3_paths.work_packages_by_project(represented.id),
            method: :post
          }
        end

        link :categories do
          { href: api_v3_paths.categories(represented.id) }
        end

        link :versions do
          { href: api_v3_paths.versions_by_project(represented.id) }
        end

        link :types,
             cache_if: -> {
               current_user_allowed_to(:view_work_packages, context: represented) ||
                 current_user_allowed_to(:manage_types, context: represented)
             } do
          { href: api_v3_paths.types_by_project(represented.id) }
        end

        property :id, render_nil: true
        property :identifier,   render_nil: true

        property :name,         render_nil: true
        property :description,  render_nil: true

        property :created_on,
                 as: 'createdAt',
                 exec_context: :decorator,
                 getter: ->(*) { datetime_formatter.format_datetime(represented.created_on) }
        property :updated_on,
                 as: 'updatedAt',
                 exec_context: :decorator,
                 getter: ->(*) { datetime_formatter.format_datetime(represented.updated_on) }

        def _type
          'Project'
        end

        self.checked_permissions = [:add_work_packages]
      end
    end
  end
end
