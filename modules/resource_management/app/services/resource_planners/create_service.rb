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

module ResourcePlanners
  class CreateService < ::BaseServices::Create
    protected

    # STI sets `type` during `.new`, before the model is extended with
    # ChangedBySystem; mark that initial change as system-made so the contract
    # does not flag `type` as a user-written readonly attribute.
    def instance(_params)
      planner = model || ResourcePlanner.new
      planner.extend(OpenProject::ChangedBySystem) unless planner.is_a?(OpenProject::ChangedBySystem)
      planner.changed_by_system(planner.changes)
      planner
    end

    def validate_params
      default_view_class_name = params[:default_view_class_name]
      return super if ResourcePlanner.allowed_children.include?(default_view_class_name)

      errors = ActiveModel::Errors.new(model || ResourcePlanner.new)
      errors.add(:default_view_class_name, :inclusion,
                 message: "is not in the list of allowed children")
      ServiceResult.failure(errors:)
    end

    def set_attributes_params(params)
      super.except(:default_view_class_name, :favorite)
    end

    def after_perform(call)
      # No default view is set here: the initial child view (and the planner's
      # `default_view_id`) is created in a second dialog step by
      # ResourcePlannerViews::CreateService.
      call.result.add_favoriting_user(user) if call.success? && params[:favorite]
      call
    end
  end
end
