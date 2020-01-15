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
module DevelopmentData
  class ProjectsSeeder < Seeder
    def seed_data!
      # We are relying on the default_projects_modules setting to set the desired project modules
      puts ' ↳ Creating development projects...'

      puts '   -Creating/Resetting development projects'
      projects = reset_projects

      puts '   -Setting members.'
      set_members(projects)

      puts '   -Creating versions.'
      seed_versions(projects)

      puts '   -Linking custom fields.'

      link_custom_fields(projects.detect { |p| p.identifier == 'dev-custom-fields' })
    end

    def applicable?
      Project.where(identifier: project_identifiers).count == 0
    end

    def project_identifiers
      %w(dev-empty dev-large dev-large-child dev-custom-fields)
    end

    def reset_projects
      Project.where(identifier: project_identifiers).destroy_all
      project_identifiers.map do |id|
        project = Project.new project_data(id)

        if id == 'dev-large-child'
          project.parent_id = Project.find_by(identifier: 'dev-large').id
        end

        project.save!
        project
      end
    end

    def set_members(projects)
      %w(reader member project_admin).each do |id|
        user = User.find_by!(login: id)
        role = Role.find_by!(name: I18n.t("default_role_#{id}"))

        projects.each { |p| Member.create! project: p, user: user, roles: [role] }
      end
    end

    def seed_versions(projects)
      projects.each do |p|
        version_data = project_data_for('scrum-project', 'versions')
        if version_data.is_a? Array
          version_data.each do |attributes|
            p.versions << Version.create!(
              name:    attributes[:name],
              status:  attributes[:status],
              sharing: attributes[:sharing]
            )
          end
        end
      end
    end

    def link_custom_fields(cf_project)
      cf_project.work_package_custom_field_ids = CustomField.where("name like 'CF DEV%'").pluck(:id)
      cf_project.save!
    end

    def project_data(identifier)
      {
        name:                 identifier.humanize,
        identifier:           identifier,
        enabled_module_names: project_modules,
        types:                Type.all
      }
    end

    def project_modules
      Setting.default_projects_modules - %w(news wiki meetings calendar)
    end
  end
end
