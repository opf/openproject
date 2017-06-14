#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
module DemoData
  class ProjectSeeder < Seeder
    # Careful: The seeding recreates the seeded project before it runs, so any changes
    # on the seeded project will be lost.
    def seed_data!
      # We are relying on the default_projects_modules setting to set the desired project modules
      puts ' ↳ Creating demo project...'

      puts '   -Creating/Resetting Demo project'
      project = reset_demo_project

      puts '   -Setting members.'
      set_members(project)

      puts '   -Creating timeline.'
      seed_timeline(project)

      puts '   -Creating versions.'
      seed_versions(project)

      puts '   -Creating board'
      seed_board(project)

      project_data_seeders(project).each do |seeder|
        puts "   -#{seeder.class.name.demodulize}"
        seeder.seed!
      end
    end

    def applicable?
      Project.count.zero?
    end

    def project_data_seeders(project)
      seeders = [
        DemoData::CustomFieldSeeder,
        DemoData::WorkPackageSeeder,
        DemoData::QuerySeeder
      ]

      seeders.map { |seeder| seeder.new project }
    end

    def reset_demo_project
      delete_demo_project
      create_demo_project
    end

    def create_demo_project
      Project.create! project_data
    end

    def delete_demo_project
      if delete_me = find_demo_project
        delete_me.destroy
      end
    end

    def set_members(project)
      role = Role.find_by(name: I18n.t(:default_role_project_admin))
      user = User.admin.first

      Member.create!(
        project: project,
        user:    user,
        roles:   [role]
      )
    end

    def seed_timeline(project)
      query = Query.create! project: project,
                            filters: [status_id: { operator: "o" }],
                            name: 'Timeline',
                            user_id: User.admin.first.id,
                            is_public: true,
                            show_hierarchies: true,
                            timeline_visible: true,
                            column_names: [:subject, :type, :status],
                            sort_criteria: [['id', 'asc']],
                            timeline_zoom_level: 'weeks'

      MenuItems::QueryMenuItem.create! navigatable_id: query.id,
                                       name: SecureRandom.uuid,
                                       title: query.name
    end

    def seed_versions(project)
      version_data = I18n.t('seeders.demo_data.project.versions')
      version_data.each do |attributes|
        project.versions << Version.create!(
          name:    attributes[:name],
          status:  attributes[:status],
          sharing: attributes[:sharing]
        )
      end
    end

    def seed_board(project)
      Board.create!(
        project:     project,
        name:        I18n.t('seeders.demo_data.board.name'),
        description: I18n.t('seeders.demo_data.board.description')
      )
    end

    module Data
      module_function

      def project_data
        {
          name:                 project_name,
          identifier:           project_identifier,
          description:          project_description,
          enabled_module_names: project_modules,
          types:                project_types
        }
      end

      def project_name
        I18n.t('seeders.demo_data.project.name')
      end

      def project_identifier
        I18n.t('seeders.demo_data.project.identifier')
      end

      def project_description
        I18n.t('seeders.demo_data.project.description')
      end

      def project_types
        Type.all
      end

      def project_modules
        Setting.default_projects_modules - %w(news wiki meetings calendar)
      end

      def find_demo_project
        Project.find_by(identifier: project_identifier)
      end
    end

    include Data
  end
end
