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

def become_admin
  let(:current_user) { create(:admin) }
end

def become_non_member(&block)
  let(:current_user) { create(:user) }

  before do
    projects = block ? instance_eval(&block) : [project]

    projects.each do |p|
      current_user.memberships.select { |m| m.project_id == p.id }.each(&:destroy)
    end
  end
end

def become_member_with_permissions(permissions)
  let(:current_user) { create(:user) }

  before do
    role = create(:project_role, permissions:)

    member = build(:member, user: current_user, project:)
    member.roles = [role]
    member.save!
  end
end

def become_member_with_view_planning_element_permissions
  become_member_with_permissions [:view_work_packages]
end

def become_member_with_move_work_package_permissions
  become_member_with_permissions [:move_work_packages]
end
