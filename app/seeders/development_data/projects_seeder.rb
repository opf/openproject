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

module DevelopmentData
  class ProjectsSeeder < Seeder
    IDENTIFIERS = {
      "dev-empty" => "DEV_EMPTY",
      "dev-work-package-sharing" => "DEV_SHARE",
      "dev-large" => "DEV_LARGE",
      "dev-large-child" => "DEV_CHILD",
      "dev-custom-fields" => "DEV_CF",
      "dev-forums" => "DEV_FORUM"
    }.freeze

    def self.identifier(key)
      Setting::WorkPackageIdentifier.semantic? ? IDENTIFIERS.fetch(key) : key
    end

    def seed_data!
      # We are relying on the default_projects_modules setting to set the desired project modules
      print_status " ↳ Creating development projects..."

      print_status "   -Creating/Resetting development projects"
      projects = reset_projects

      print_status "   -Setting members."
      set_members(projects)

      print_status "   -Creating versions."
      seed_versions(projects)
    end

    def applicable?
      recent_installation? &&
        Project.where(identifier: project_identifiers).count == 0 &&
        seed_data.reference_exists?(:default_role_project_admin)
    end

    # returns true if no projects have been created more than 1 hour ago,
    # meaning this is a recent installation
    def recent_installation?
      Project.where(created_at: ..1.hour.ago).none?
    end

    def project_identifiers
      IDENTIFIERS.keys.map { |key| self.class.identifier(key) }
    end

    def reset_projects
      Project.where(identifier: project_identifiers).destroy_all
      IDENTIFIERS.keys.map do |key|
        project = Project.new project_data(key)

        if key == "dev-large-child"
          project.parent = seed_data.find_reference(:dev_large)
        end

        project.save!
        seed_data.store_reference(key.underscore.to_sym, project)

        project
      end
    end

    def set_members(projects)
      %w(reader member project_admin).each do |id|
        principal = User.find_by!(login: id)
        role = seed_data.find_reference(:"default_role_#{id}")

        projects.each { |p| Member.create! project: p, principal:, roles: [role] }
      end
    end

    def seed_versions(projects)
      version_data = seed_data.lookup("projects.scrum-project.versions")
      return unless version_data.is_a? Array

      projects.each do |project|
        version_data.each do |attributes|
          project.versions.create!(
            name: attributes["name"],
            status: attributes["status"],
            sharing: attributes["sharing"]
          )
        end
      end
    end

    def project_data(key)
      {
        name: project_name(key),
        identifier: self.class.identifier(key),
        enabled_module_names: project_modules,
        project_types: Type.all.map { |type| ProjectType.new(type:) },
        workspace_type: "project"
      }
    end

    def project_name(key)
      _dev, *parts = key.split("-")
      "[dev] #{parts.join(' ').capitalize}"
    end

    def project_modules
      Setting.default_projects_modules - %w(news wiki meetings calendar)
    end
  end
end
