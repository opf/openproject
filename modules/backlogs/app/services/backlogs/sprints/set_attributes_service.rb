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
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    def set_attributes(params)
      params = params.to_h.deep_symbolize_keys

      super(sprint_params_with_goal_attributes(params.fetch(:attributes, params)))
    end

    def sprint_params_with_goal_attributes(params)
      attributes = params.reject { |key, _| %i[goal goal_project].include?(key.to_sym) }
      goal_attributes = goal_nested_attributes(params)

      if goal_attributes
        attributes.merge(goals_attributes: [goal_attributes])
      else
        attributes
      end
    end

    def goal_nested_attributes(params)
      attributes = goal_params(params)
      return unless attributes

      project = goal_project(params)
      existing_id = existing_goal_id(project)

      return if existing_id.blank? && attributes[:text].blank?

      nested_goal_attributes(project, attributes[:text], existing_id)
    end

    def goal_params(params)
      params[:goal]&.to_h&.symbolize_keys
    end

    def goal_project(params)
      params[:goal_project] || params[:project] || model.project
    end

    def nested_goal_attributes(project, text, existing_id)
      attributes = { project_id: project.id, text: }
      attributes[:id] = existing_id if existing_id.present?
      attributes[:_destroy] = "1" if existing_id.present? && text.blank?
      attributes
    end

    def existing_goal_id(goal_project)
      return unless model.persisted?

      model.goal_for(goal_project)&.id
    end

    def sprint_name_from_predecessor
      return model.name unless model.new_record?

      predecessor = model.project.sprints.last
      next_name_in_succession(predecessor)
    end

    def set_default_attributes(_params)
      set_sprint_name
      set_default_status
    end

    def set_sprint_name
      model.name ||= sprint_name_from_predecessor
    end

    def set_default_status
      model.status ||= "in_planning"
    end

    def next_name_in_succession(predecessor)
      if predecessor.nil?
        default_sprint_name
      elsif (match = predecessor.name.match(/\A(.*)\s(\d+)\z/))
        # If the predecessor's name ends with a number, increment that number for the new sprint's name.
        # E.g., if the previous sprint was called "Be ambitious 42", the next one will be "Be ambitious 43".
        [match[1], match[2].to_i + 1].join(" ")
      else
        # The predecessor's name doesn't end with a number. The user has chosen a custom name. Do not assume
        # how the next sprint should be called. Return an empty string and let the user choose.
        ""
      end
    end

    def default_sprint_name
      [I18n.t("activerecord.models.sprint"), 1].join(" ")
    end
  end
end
