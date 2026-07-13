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
      module WorkPackageRepresenter
        module_function

        def extension # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
          ->(*) do
            property :position,
                     render_nil: true,
                     skip_render: ->(*) do
                       !(backlogs_enabled? && type&.passes_attribute_constraint?(:position, project:))
                     end

            property :story_points,
                     render_nil: true,
                     skip_render: ->(*) do
                       !(backlogs_enabled? && type&.passes_attribute_constraint?(:story_points, project:))
                     end

            resource :sprint,
                     link_cache_if: ->(*) {
                       current_user.allowed_in_project?(:view_sprints, represented.project)
                     },
                     link: ->(*) {
                       if represented.sprint.present?
                         {
                           href: api_v3_paths.sprint(represented.sprint_id),
                           title: represented.sprint.name
                         }
                       else
                         {
                           href: nil
                         }
                       end
                     },
                     getter: ->(*) do
                       if embed_links &&
                          represented.sprint.present? &&
                          current_user.allowed_in_project?(:view_sprints, represented.project)
                         ::API::V3::Sprints::SprintRepresenter.create(represented.sprint, current_user:)
                       end
                     end,
                     setter: associated_resource_default_setter(:sprint, :sprint, :sprint)

            resource :backlog_bucket,
                     link_cache_if: ->(*) {
                       current_user.allowed_in_project?(:view_sprints, represented.project)
                     },
                     link: ->(*) {
                       if represented.backlog_bucket.present?
                         {
                           href: api_v3_paths.backlog_bucket(represented.backlog_bucket_id),
                           title: represented.backlog_bucket.name
                         }
                       else
                         {
                           href: nil
                         }
                       end
                     },
                     getter: ->(*) do
                       if embed_links &&
                          represented.backlog_bucket.present? &&
                          current_user.allowed_in_project?(:view_sprints, represented.project)
                         ::API::V3::BacklogBuckets::BacklogBucketRepresenter.create(represented.backlog_bucket, current_user:)
                       end
                     end,
                     setter: associated_resource_default_setter(:backlog_bucket, :backlog_bucket, :backlog_bucket)
          end
        end
      end
    end
  end
end
