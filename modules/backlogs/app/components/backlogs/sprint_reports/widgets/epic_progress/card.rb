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
                as_of.where(id: historic_descendant_ids([epic.id])).visible(current_user)
              else
                epic.descendants.visible(current_user)
              end
          end

          def resolved_work_packages_count
            @resolved_work_packages_count ||= work_packages_in_epic.where(status: project.statuses_considered_closed).count
          end

          def total_work_packages_count
            @total_work_packages_count ||= work_packages_in_epic.count
          end

          def historic_descendant_ids(ids)
            found = Set.new
            children = ids

            until children.empty?
              children = as_of.where(parent_id: children).pluck(:id).to_set - found
              found.merge(children)
            end

            found
          end
        end
      end
    end
  end
end
