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
    include Layout
    include PaginationHelper

    helper ResourceManagement::PlannerRoutes

    before_action :ensure_resource_management_licensed

    # Loads `@project` from `:project_id` and authorizes a controller whose
    # actions serve a planner both inside a project and globally.
    #
    # The project routes take the regular controller-action check. The global
    # ones cannot: they admit holders of `view_global_resource_planners` as well
    # as members of a project granting `view_resource_planners`, and since the
    # same actions serve both scopes, mapping the global permission onto them in
    # the engine would also let it pass on the project routes and open every
    # project's planners. Which planners the user then gets to see is decided by
    # `ResourcePlanner.visible_to`.
    def self.load_and_authorize_in_planner_section(**options)
      # `Accounts::Authorization` only recognises its own method names as an
      # authorization check, so ours has to be affirmed.
      authorization_checked_by_default_action(**options.slice(:only, :except))

      before_action(**options) do
        if params[:project_id].present?
          load_and_authorize_in_optional_project
        else
          render_403 unless ResourcePlanner.section_visible_to?(current_user)
        end
      end
    end

    private

    # Named (rather than the `guard_enterprise_feature` macro) so individual
    # actions can opt out via `skip_before_action` — the planners index renders
    # an upsell banner instead of a 403 when the feature is not licensed.
    def ensure_resource_management_licensed
      perform_enterprise_feature_guard(:resource_management)
    end

    def find_resource_planner(param_key = :resource_planner_id)
      @resource_planner = ResourcePlanner
                            .visible_to(current_user, @project)
                            .with_children
                            .find(params.expect(param_key))
    end

    # Allow-lists the type before constantizing it, since it may be
    # user-supplied. Returns nil for an unknown type or unreachable id, letting
    # the caller's validations surface the error.
    def resolve_visible_entity(entity_type, entity_id)
      return if entity_id.blank?
      return unless ResourceAllocation::ALLOWED_ENTITY_TYPES.include?(entity_type)

      scope = entity_type.constantize.visible(current_user)
      scope = scope.where(project: @project) if @project
      scope.find_by(id: entity_id)
    end
  end
end
