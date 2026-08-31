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

module DevelopmentData
  module ResourceManagement
    # Seeds a resource planner into each seeded project that carries `resource_planner` seed data.
    # Development data, because the allocations it creates are for the users seeded by the
    # DepartmentSeeder. It runs after the demo data, whose projects and work packages it augments.
    class ResourcePlannersSeeder < ::Seeder
      def seed_data!
        seed_data.each_data("projects") do |project_data|
          project = find_project(project_data)
          next if project.nil?

          ::ResourceManagement::DevelopmentData::ResourcePlannerSeeder.new(project, project_data).seed!
        end
      end

      def applicable?
        ::ResourcePlanner.none?
      end

      def not_applicable_message
        "Skipping resource planners as there are already some configured"
      end

      private

      def find_project(project_data)
        Project.find_by(identifier: project_data.lookup("identifier"))
      end
    end
  end
end
