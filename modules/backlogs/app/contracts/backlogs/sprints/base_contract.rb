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

module Backlogs::Sprints
  class BaseContract < ::ModelContract
    SPRINT_ATTRIBUTES = %w[name project_id start_date finish_date].freeze

    validate :user_authorized_for_sprint_attributes
    validate :user_authorized_for_goal_attributes

    def self.model
      Sprint
    end

    attribute :name
    attribute :project_id
    attribute :start_date
    attribute :finish_date
    attribute :goals_attributes, readable: false

    private

    def user_authorized_for_sprint_attributes
      return unless model.project
      return unless sprint_attributes_changed?

      unless user.allowed_in_project?(:create_sprints, model.project)
        errors.add :base, :error_unauthorized
      end
    end

    def sprint_attributes_changed?
      model.new_record? || model.changed.intersect?(SPRINT_ATTRIBUTES)
    end

    def user_authorized_for_goal_attributes
      changed_goals.each do |goal|
        project = goal.project

        unless project && sprint_visible_to_goal_project?(project) && user.allowed_in_project?(:create_sprints, project)
          errors.add :base, :error_unauthorized
        end
      end
    end

    def changed_goals
      goals_association = model.association(:goals)
      return [] unless goals_association.loaded? || goals_association.target.any?

      goals_association.target.select { |goal| goal.changed? || goal.marked_for_destruction? }
    end

    def sprint_visible_to_goal_project?(project)
      if model.new_record?
        model.project == project
      else
        model.visible_to?(project)
      end
    end
  end
end
