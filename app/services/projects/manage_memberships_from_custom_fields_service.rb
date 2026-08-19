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

module Projects
  class ManageMembershipsFromCustomFieldsService < ::BaseServices::BaseCallable
    attr_reader :project, :user, :custom_field

    def initialize(user:, project:, custom_field:)
      super()

      @custom_field = custom_field
      @user = user
      @project = project
    end

    private

    def perform # rubocop:disable Metrics/AbcSize
      users_to_remove = params[:old_value] - params[:new_value]
      users_to_add = params[:new_value] - params[:old_value]

      if users_to_add.present?
        Principal.where(id: users_to_add).find_each do |add_user|
          add_member_or_add_role_to_member(add_user)
        end
      end

      if users_to_remove.present?
        Principal.where(id: users_to_remove).find_each do |remove_user|
          remove_member_or_remove_role_from_member(remove_user)
        end
      end

      ServiceResult.success(result: project)
    end

    def add_member_or_add_role_to_member(add_user) # rubocop:disable Metrics/AbcSize
      user_member = project.member_principals.find_by(principal: add_user)

      if user_member
        new_role_ids = (user_member.role_ids + [custom_field.role.id]).uniq

        Members::UpdateService
         .new(user:, model: user_member, contract_class: EmptyContract)
         .call(role_ids: new_role_ids)
      else
        Members::CreateService
          .new(user:, contract_class: EmptyContract)
          .call(roles: [custom_field.role], project:, principal: add_user)
      end
    end

    def remove_member_or_remove_role_from_member(remove_user)
      user_member = project.member_principals.find_by(principal: remove_user)

      return unless user_member

      new_role_ids = user_member.role_ids - [custom_field.role.id]

      if new_role_ids.empty?
        Members::DeleteService
          .new(user:, model: user_member, contract_class: EmptyContract)
          .call
      else
        Members::UpdateService
          .new(user:, model: user_member, contract_class: EmptyContract)
          .call(role_ids: new_role_ids)
      end
    end
  end
end
