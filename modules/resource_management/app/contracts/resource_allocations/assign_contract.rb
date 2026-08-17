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

module ResourceAllocations
  # Assigning a real user to a generic (filter-based) allocation. Only
  # `principal` and `principal_assigned_by` change; `principal_explicit`,
  # `user_filter` and `filter_name` are kept untouched.
  class AssignContract < BaseContract
    attribute :principal_assigned_by

    validate :allocation_is_generic
    validate :principal_matches_filter

    private

    # This action is gated on its own permission rather than `allocate_user_resources`.
    def user_allowed_to_allocate
      return if model.project.nil?
      return if user.allowed_in_project?(:assign_users_to_generic_allocations, model.project)

      errors.add :base, :error_unauthorized
    end

    # Staffing only ever assigns to generic placeholders. An explicit allocation
    # is managed through the regular allocation flow.
    def allocation_is_generic
      errors.add :base, :error_unauthorized if model.principal_explicit?
    end

    # The assigned user must be a project member that the stored filter selects,
    # so a tampered `principal_id` cannot assign an arbitrary user.
    def principal_matches_filter
      return if model.principal.nil? || model.project.nil?
      return if principal_selected_by_filter?

      errors.add :principal, :invalid
    end

    def principal_selected_by_filter?
      model.candidate_query.results.exists?(id: model.principal_id)
    end
  end
end
