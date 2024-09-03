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
module DemoData
  class ProjectsSeeder < Seeder
    # Careful: The seeding recreates the seeded project before it runs, so any changes
    # on the seeded project will be lost.
    # On the other hand, it won't be applied if there are already existing projects.
    def seed_data!
      print_status " ↳ Updating settings"
      seed_settings

      seed_data.each_data("projects") do |project_data|
        seed_project(project_data)
        Setting.demo_projects_available = true
      end

      print_status " ↳ Update form configuration with global queries"
      seed_form_configuration
    end

    def applicable?
      Project.count.zero?
    end

    def seed_settings
      seedable_welcome_settings
        .select { |k,| Settings::Definition[k].writable? }
        .each do |k, v|
        Setting[k] = v
      end
    end

    def seed_project(project_data)
      project_seeder = ProjectSeeder.new(project_data)
      project_seeder.seed!
    end

    def seed_form_configuration
      BasicData::TypeConfigurationSeeder.new(seed_data).seed!
    end

    def seedable_welcome_settings
      welcome = seed_data.lookup("welcome")
      return {} if welcome.blank?

      {
        welcome_title: welcome.lookup("title"),
        welcome_text: welcome.lookup("text"),
        welcome_on_homescreen: 1
      }
    end
  end
end
