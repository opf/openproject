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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module CustomFields
  class LinkWithRoleService < ::BaseServices::Update
    attr_accessor :old_role, :new_role

    protected

    def after_perform(service_call)
      super.tap do
        modify_existing_memberships
      end
    end

    private

    def set_attributes(params)
      self.old_role = model.role
      self.new_role = params[:role_id].present? ? ProjectRole.find(params[:role_id]) : nil

      super
    end

    def modify_existing_memberships # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      return if old_role == new_role

      model.custom_values.group_by(&:customized).each do |project, custom_values|
        user_ids = custom_values.map { |cv| cv.value.to_i }
        Principal.includes(:members).where(id: user_ids).find_each do |member_user|
          user_member = member_user.members.where(project: project, entity: nil).first

          if user_member
            new_role_ids = (user_member.role_ids + [new_role&.id] - [old_role&.id]).compact.uniq

            if new_role_ids.empty?
              Members::DeleteService
               .new(user:, model: user_member, contract_class: EmptyContract)
               .call
            else
              Members::UpdateService
               .new(user:, model: user_member, contract_class: EmptyContract)
               .call(role_ids: new_role_ids)
            end
          elsif new_role.present?
            Members::CreateService
              .new(user:, contract_class: EmptyContract)
              .call(roles: [new_role], project:, principal: member_user)
          end
        end
      end
    end
  end
end
