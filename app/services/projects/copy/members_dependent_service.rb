#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Projects::Copy
  class MembersDependentService < ::Copy::Dependency
    protected

    def copy_dependency(*)
      # Copy users first, then groups to handle members with inherited and given roles
      members_to_copy = []
      members_to_copy += source.memberships.select { |m| m.principal.is_a?(User) }
      members_to_copy += source.memberships.reject { |m| m.principal.is_a?(User) }
      members_to_copy.each do |member|
        new_member = Member.new
        new_member.send(:assign_attributes, member.attributes.dup.except('id', 'project_id', 'created_on'))
        # only copy non inherited roles
        # inherited roles will be added when copying the group membership
        role_ids = member.member_roles.reject(&:inherited?).map(&:role_id)
        next if role_ids.empty?

        new_member.role_ids = role_ids
        new_member.project = target
        target.memberships << new_member
        new_member.save
      end
    end
  end
end
