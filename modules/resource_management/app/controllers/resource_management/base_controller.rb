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

module ::ResourceManagement
  class BaseController < ::ApplicationController
    private

    # Loads the resource planner (with its child views) scoped to the current
    # project and the current user's visibility. Defaults to the nested
    # +:resource_planner_id+ route param; controllers where the planner is the
    # primary resource pass +:id+.
    def find_resource_planner(param_key = :resource_planner_id)
      @resource_planner = ResourcePlanner
                            .visible(current_user)
                            .where(project: @project)
                            .with_children
                            .find(params.expect(param_key))
    end

    # Resolves a polymorphic allocation entity from a (potentially user-supplied)
    # type and id, scoped to the current project and the current user's
    # visibility. Allow-lists the type before constantizing it; returns nil for an
    # unknown type or unreachable id, letting the caller's validations surface the
    # error.
    def resolve_visible_entity(entity_type, entity_id)
      return if entity_id.blank?
      return unless ResourceAllocation::ALLOWED_ENTITY_TYPES.include?(entity_type)

      entity_type.constantize.visible(current_user).where(project: @project).find_by(id: entity_id)
    end
  end
end
