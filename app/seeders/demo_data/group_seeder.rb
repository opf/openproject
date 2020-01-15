#-- encoding: UTF-8

#-- copyright

# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
module DemoData
  class GroupSeeder < Seeder
    attr_accessor :user
    include ::DemoData::References

    def initialize
      self.user = User.admin.first
    end

    def seed_data!
      print '    ↳ Creating groups'

      seed_groups

      puts
    end

    def add_projects_to_groups
      groups = demo_data_for('groups')
      if groups.present?
        groups.each do |group_attr|
          if group_attr[:projects].present?
            group = Group.find_by(lastname: group_attr[:name])
            group_attr[:projects].each do |project_attr|
              project = Project.find(project_attr[:name])
              role = Role.find_by(name: project_attr[:role])

              Member.create!(
                project: project,
                principal: group,
                roles: [role]
              )
            end
          end
        end
      end
    end

    private

    def seed_groups
      groups = demo_data_for('groups')
      if groups.present?
        groups.each do |group_attr|
          print '.'
          create_group group_attr[:name]
        end
      end
    end

    def create_group(name)
      Group.create lastname: name
    end
  end
end
