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
    module TimeEntries
      class TimeEntriesActivityRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource

        self_link

        property :id

        property :name

        property :position

        property :is_default,
                 as: :default

        associated_resources :projects,
                             link: ->(*) {
                               active_projects.map do |project|
                                 {
                                   href: api_v3_paths.project(project.identifier),
                                   title: project.name
                                 }
                               end
                             },
                             getter: ->(*) {
                               next unless embed_links

                               active_projects.map do |project|
                                 Projects::ProjectRepresenter.create(project, current_user:)
                               end
                             }

        def _type
          "TimeEntriesActivity"
        end

        def active_projects
          Project.visible_with_activated_time_activity(represented) if embed_links

          Project.none
        end
      end
    end
  end
end
