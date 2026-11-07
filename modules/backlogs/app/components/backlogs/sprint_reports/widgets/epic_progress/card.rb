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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Backlogs
  module SprintReports
    module Widgets
      class EpicProgress < Grids::WidgetComponent
        class Card < ApplicationComponent
          include OpPrimer::ComponentHelpers
          include Backlogs::Concerns::TimeConsciousScope

          attr_reader :epic, :sprint, :project, :current_user

          def self.percentage(resolved:, total:)
            return 0 if total.zero? || resolved.zero?

            [resolved * 100 / total, 1].max
          end

          def initialize(epic:, sprint:, project:, current_user: User.current)
            super()

            @epic = epic
            @sprint = sprint
            @project = project
            @current_user = current_user
          end

          def resolved_percentage
            self.class.percentage(resolved: resolved_work_packages_count, total: total_work_packages_count)
          end

          private

          def work_packages_in_epic
            @work_packages_in_epic ||=
              if historic?
                work_packages_at_report_time.where(id: descendant_ids_excluding_sub_epic_descendants).visible(current_user)
              else
                epic.descendants.where.not(id: sub_epic_descendant_ids).visible(current_user)
              end
          end

          def sub_epic_descendant_ids
            WorkPackage.with_ancestor(epic.descendants.where(type_id: epic.type_id)).select(:id)
          end

          def resolved_work_packages_count
            @resolved_work_packages_count ||= work_packages_in_epic.where(status: project.statuses_considered_closed).count
          end

          def total_work_packages_count
            @total_work_packages_count ||= work_packages_in_epic.count
          end

          def descendant_ids_excluding_sub_epic_descendants
            found = Set.new
            parent_ids = [epic.id]

            until parent_ids.empty?
              child_ids, sub_epic_ids = child_ids_and_sub_epic_ids(parent_ids)
              new_ids = child_ids - found

              found.merge(new_ids)
              parent_ids = new_ids - sub_epic_ids
            end

            found
          end

          def child_ids_and_sub_epic_ids(parent_ids)
            rows = work_packages_at_report_time.where(parent_id: parent_ids).pluck(:id, :type_id)
            sub_epic_rows = rows.select { |_id, type_id| type_id == epic.type_id }

            [rows.to_set(&:first), sub_epic_rows.to_set(&:first)]
          end
        end
      end
    end
  end
end
