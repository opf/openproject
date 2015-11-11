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
      puts ' ↳ Creating demo project...'

      puts '   -Creating/Resetting Demo project'
      project = reset_demo_project

      puts '   -Setting modules.'
      set_modules(project)

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

    def project_data_seeders(project)
      seeders = [
        DemoData::CustomFieldSeeder,
        DemoData::WikiSeeder,
        DemoData::WorkPackageSeeder,
        DemoData::QuerySeeder
      ]

      seeders.map { |seeder| seeder.new project }
    end

    def reset_demo_project
      if delete_me = Project.find_by(identifier: I18n.t('seeders.demo_data.project.identifier'))
        delete_me.destroy
      end

      Project.create!(
        name:         I18n.t('seeders.demo_data.project.name'),
        identifier:   I18n.t('seeders.demo_data.project.identifier'),
        description:  I18n.t('seeders.demo_data.project.description'),
        types:        Type.all
      )
    end

    def set_modules(project)
      project.enabled_module_names += ['timelines']
      project.enabled_module_names -= ['repository']
    end

    def set_members(project)
      role = Role.find_by(name: I18n.t(:default_role_project_admin))
      user = User.admin.first

      Member.create!(
        project: project,
        user:    user,
        roles:   [role],
      )
    end

    def seed_timeline(project)
      timeline = Timeline.create!(
        project: project,
        name: I18n.t('seeders.demo_data.timeline.name'),
        options: {
          'zoom_factor' => ['3'],
          'initial_outline_expansion' => ['2'],
          'columns' => [:start_date, :due_date, :status]
        }
      )
    end

    def seed_versions(project)
      version_data = I18n.t('seeders.demo_data.project.versions')
      version_data.each do |attributes|
        project.versions << Version.create!(
          name:    attributes[:name],
          status:  I18n.t(attributes[:status]),
          sharing: I18n.t(attributes[:sharing])
        )
      end
    end

    def seed_board(project)
      user = User.admin.first

      board = Board.create!(
        project:     project,
        name:        I18n.t('seeders.demo_data.board.name'),
        description: I18n.t('seeders.demo_data.board.description')
      )
    end
  end
end
