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

module Departments
  class AddUserService < ::BaseServices::BaseContracted
    def initialize(department, user:, contract_class: AdminOnlyContract)
      self.model = department
      super(user:, contract_class:)
    end

    private

    def persist(call)
      user_id = params[:user_id].to_i
      existing_department = find_existing_department(user_id)

      if existing_department.nil? || existing_department.id == model.id
        add_user_to_department(model, user_id, call)
      else
        handle_existing_membership(existing_department, user_id, call)
      end

      call
    end

    def handle_existing_membership(existing_department, user_id, call)
      if existing_department.ldap_managed?
        # The user is locked into an LDAP-managed department and cannot be moved out manually.
        reject_move_from_managed(existing_department, call)
      elsif params[:remove_from_previous_department]
        move_user(from: existing_department, to: model, user_id:, call:)
      else
        call.success = false
        call.result = existing_department
      end
    end

    def reject_move_from_managed(existing_department, call)
      call.success = false
      call.result = existing_department
      call.errors.add(:base, :user_in_ldap_managed_department)
    end

    def find_existing_department(user_id)
      GroupUser
        .joins(:group)
        .merge(Group.organizational_units)
        .where(user_id:)
        .first
        &.group
    end

    def add_user_to_department(department, user_id, call)
      result = Groups::UpdateService
        .new(user:, model: department)
        .call(add_user_ids: [user_id])

      call.add_dependent!(result)
    end

    def remove_user_from_department(department, user_id, call)
      result = Groups::UpdateService
        .new(user:, model: department)
        .call(remove_user_ids: [user_id])

      call.add_dependent!(result)
    end

    def move_user(from:, to:, user_id:, call:)
      Group.transaction do
        remove_user_from_department(from, user_id, call)
        raise ActiveRecord::Rollback unless call.success?

        add_user_to_department(to, user_id, call)
        raise ActiveRecord::Rollback unless call.success?
      end
    end
  end
end
