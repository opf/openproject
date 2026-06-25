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

module CostEntries
  class UpdateContract < BaseContract
    include UnchangedProject

    validate :validate_user_allowed_to_update

    def validate_user_allowed_to_update
      errors.add :base, :error_unauthorized unless user_allowed_to_update?
    end

    ##
    # Users may update cost entries IF they have the :edit_cost_entries
    # permission, or it is their own entry and they have :edit_own_cost_entries.
    # The permission is checked both in the original and the target project to
    # prevent privilege escalation when moving an entry between projects.
    def user_allowed_to_update?
      with_unchanged_project_id do
        user_allowed_to_update_in?(model)
      end && user_allowed_to_update_in?(model)
    end

    private

    def user_allowed_to_update_in?(cost_entry)
      user.allowed_in_project?(:edit_cost_entries, cost_entry.project) ||
        (own_entry? && user.allowed_in_project?(:edit_own_cost_entries, cost_entry.project))
    end

    # Whether the entry is the acting user's own entry. The previous owner is
    # checked alongside the current one so that authorization cannot be gained by
    # reassigning another user's entry to oneself within the same request.
    def own_entry?
      model.user_id_was == user.id && model.user == user
    end
  end
end
