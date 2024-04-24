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

module Projects::Concerns
  module NewProjectService
    private

    def after_perform(attributes_call)
      new_project = attributes_call.result

      set_default_role(new_project) unless user.admin?
      notify_project_created(new_project)

      super
    end

    # Add default role to the newly created project
    # based on the setting ('new_project_user_role_id')
    # defined in the administration. Will either create a new membership
    # or add a role to an already existing one.
    def set_default_role(new_project)
      role = ProjectRole.in_new_project

      return unless role && new_project.persisted?

      # Assuming the members are loaded anyway
      user_member = new_project.members.detect { |m| m.principal == user }

      if user_member
        Members::UpdateService
          .new(user:, model: user_member, contract_class: EmptyContract)
          .call(role_ids: user_member.role_ids + [role.id])
      else
        Members::CreateService
          .new(user:, contract_class: EmptyContract)
          .call(roles: [role], project: new_project, principal: user)
      end
    end

    def notify_project_created(new_project)
      OpenProject::Notifications.send(
        OpenProject::Events::PROJECT_CREATED,
        project: new_project
      )
    end
  end
end
