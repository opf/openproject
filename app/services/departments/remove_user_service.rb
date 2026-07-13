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
  class RemoveUserService < ::BaseServices::BaseContracted
    def initialize(department, user:, contract_class: AdminOnlyContract)
      self.model = department
      super(user:, contract_class:)
    end

    private

    def persist(call)
      if model.ldap_managed?
        # The membership of an LDAP-managed department is owned by LDAP and cannot be changed manually.
        call.success = false
        call.errors.add(:base, :user_in_ldap_managed_department)
        return call
      end

      result = Groups::UpdateService
        .new(user:, model:)
        .call(remove_user_ids: [params[:user_id].to_i])

      call.add_dependent!(result)
      call
    end
  end
end
