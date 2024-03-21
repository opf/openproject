#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Projects::Copy
  class MembersDependentService < Dependency
    def self.human_name
      I18n.t(:'projects.copy.members')
    end

    def source_count
      source.members.count
    end

    protected

    def copy_dependency(*)
      # Copy users and placeholder users first,
      # then groups to handle members with inherited and given roles
      source.memberships.sort_by { |m| m.principal.is_a?(Group) ? 1 : 0 }.each do |member|
        create_membership(member)
      end
    end

    def create_membership(member)
      # only copy non inherited roles
      # inherited roles will be added when copying the group membership
      role_ids = member.member_roles.reject(&:inherited?).map(&:role_id)

      return if role_ids.empty?

      attributes = member
                     .attributes.dup.except('id', 'project_id', 'created_at', 'updated_at')
                     .merge(role_ids:,
                            project: target,
                            # This is magic for now. The settings has been set before in the Projects::CopyService
                            # It would be better if this was not sneaked in but rather passed in as a parameter.
                            send_notifications: ActionMailer::Base.perform_deliveries)

      Members::CreateService
        .new(user: User.current, contract_class: EmptyContract)
        .call(attributes)
    end
  end
end
