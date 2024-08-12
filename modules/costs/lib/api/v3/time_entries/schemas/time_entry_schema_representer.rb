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
      module Schemas
        class TimeEntrySchemaRepresenter < ::API::Decorators::SchemaRepresenter
          extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass
          custom_field_injector type: :schema_representer

          def self.represented_class
            TimeEntry
          end

          schema :id,
                 type: "Integer"

          schema :created_at,
                 type: "DateTime"

          schema :updated_at,
                 type: "DateTime"

          schema :spent_on,
                 type: "Date"

          schema :hours,
                 type: "Duration"

          schema :comment,
                 type: "Formattable",
                 required: false

          schema :ongoing,
                 type: "Boolean",
                 required: false

          schema_with_allowed_link :user,
                                   has_default: false,
                                   required: true,
                                   href_callback: ->(*) {
                                     allowed_user_href
                                   }

          schema_with_allowed_link :work_package,
                                   has_default: false,
                                   required: false,
                                   href_callback: ->(*) {
                                     allowed_work_package_href
                                   }

          schema_with_allowed_link :project,
                                   has_default: false,
                                   required: false,
                                   href_callback: ->(*) {
                                     allowed_projects_href
                                   }

          schema_with_allowed_collection :activity,
                                         type: "TimeEntriesActivity",
                                         value_representer: TimeEntriesActivityRepresenter,
                                         has_default: true,
                                         required: false,
                                         link_factory: ->(value) {
                                           {
                                             href: api_v3_paths.time_entries_activity(value.id),
                                             title: value.name
                                           }
                                         }

          def allowed_work_package_href
            if represented.new_record?
              api_v3_paths.time_entries_available_work_packages_on_create
            else
              api_v3_paths.time_entries_available_work_packages_on_edit(represented.id)
            end
          end

          def allowed_projects_href
            api_v3_paths.time_entries_available_projects
          end

          def allowed_user_href
            api_v3_paths.path_for :principals,
                                  filters: [
                                    { status: { operator: "!", values: [Principal.statuses[:locked].to_s] } },
                                    { type: { operator: "=", values: ["User"] } },
                                    { member: { operator: "=", values: [represented.project_id] } }
                                  ]
          end
        end
      end
    end
  end
end
