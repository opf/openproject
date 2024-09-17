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

module API
  module V3
    module Views
      class ViewRepresenter < ::API::Decorators::Single
        include API::Decorators::DateProperty
        include API::Decorators::LinkedResource

        self_link path: :view, title_getter: ->(*) {}

        associated_resource :query
        resource :project,
                 getter: ->(*) {
                   next unless represented.query.project

                   ::API::V3::Projects::ProjectRepresenter
                     .create(represented.query.project, current_user:, embed_links:)
                 },
                 link: ->(*) {
                   if represented.query.project
                     {
                       href: api_v3_paths.project(represented.query.project.id),
                       title: represented.query.project.name
                     }
                   else
                     {
                       href: nil,
                       title: nil
                     }
                   end
                 },
                 setter: ->(fragment:, represented:, **) {
                   link = ::API::Decorators::LinkObject.new(represented,
                                                            path: :project,
                                                            property_name: :project,
                                                            getter: :project_id,
                                                            setter: :"project_id=")

                   link.from_hash(fragment)
                 }

        property :id

        property :public,
                 getter: ->(*) {
                   query.public
                 }

        property :starred,
                 getter: ->(*) {
                   query.starred
                 }

        property :name,
                 getter: ->(*) {
                   query.name
                 }

        date_time_property :created_at

        date_time_property :updated_at

        def _type
          "Views::#{Constants::Views.type(represented.type)}"
        end
      end
    end
  end
end
