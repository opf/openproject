# frozen_string_literal: true

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

module OpenProject::Backlogs
  module Patches
    module API
      module WorkPackageSchemaRepresenter
        module_function

        # rubocop:disable Metrics/AbcSize
        def extension
          ->(*) do
            schema :position,
                   type: "Integer",
                   required: false,
                   show_if: ->(*) {
                     backlogs_constraint_passed?(:position)
                   }

            schema :story_points,
                   type: "Integer",
                   required: false,
                   show_if: ->(*) {
                     backlogs_constraint_passed?(:story_points)
                   }

            schema_with_allowed_link :sprint,
                                     has_default: false,
                                     required: false,
                                     show_if: ->(*) {
                                       current_user.allowed_in_project?(:view_sprints, represented.project) &&
                                         backlogs_constraint_passed?(:sprint)
                                     },
                                     href_callback: ->(*) {
                                       filters = CGI.escape(JSON.dump(
                                                              [{ status: { operator: "!",
                                                                           values: [Sprint.statuses["completed"]] } }]
                                                            ))
                                       query = "filters=#{filters}&pageSize=-1"

                                       "#{api_v3_paths.project_sprints(represented.project_id)}?#{query}"
                                     }

            schema_with_allowed_link :backlog_bucket,
                                     has_default: false,
                                     required: false,
                                     show_if: ->(*) {
                                       current_user.allowed_in_project?(:view_sprints, represented.project) &&
                                         backlogs_constraint_passed?(:backlog_bucket)
                                     },
                                     href_callback: ->(*) {
                                       filters = CGI.escape(JSON.dump([]))
                                       query = "filters=#{filters}&pageSize=-1"

                                       "#{api_v3_paths.project_backlog_buckets(represented.project_id)}?#{query}"
                                     }

            define_method :backlogs_constraint_passed? do |attribute|
              !represented.type || represented.type.passes_attribute_constraint?(attribute, project: represented.project)
            end
          end
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
