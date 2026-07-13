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
  class BaseContract < ::ModelContract
    def self.model
      ResourcePlanner
    end

    attribute :name

    stored_attribute :start_date, store: :options
    stored_attribute :end_date, store: :options

    validate :user_allowed_to_manage

    private

    def user_allowed_to_manage
      return if model.project.nil?
      return if user_is_owner_with_view_permission? || user_can_manage_public?

      errors.add :base, :error_unauthorized
    end

    def user_is_owner_with_view_permission?
      model.principal == user &&
        user.allowed_in_project?(:view_resource_planners, model.project)
    end

    def user_can_manage_public?
      model.public? &&
        user.allowed_in_project?(:manage_public_resource_planners, model.project)
    end
  end
end
