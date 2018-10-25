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
      ["scrum-project", "demo-project"].each do |key|
        puts " ↳ Creating #{key} project..."

        puts '   -Creating/Resetting project'
        project = reset_project key

        puts '   -Setting members.'
        set_members(project)

        puts '   -Creating news.'
        seed_news(project, key)

        puts '   -Assigning types.'
        set_types(project, key)

        puts '   -Creating categories'
        seed_categories(project, key)

        puts '   -Creating versions.'
        seed_versions(project, key)

        puts '   -Creating queries.'
        seed_queries(project, key)

        project_data_seeders(project, key).each do |seeder|
          puts "   -#{seeder.class.name.demodulize}"
          seeder.seed!
        end

        Setting.demo_projects_available = 'true'
      end

      puts ' ↳ Updating settings'
      seed_settings
    end

    def applicable?
      Project.count.zero?
    end

    def project_data_seeders(project, key)
      seeders = [
        DemoData::WikiSeeder,
        DemoData::CustomFieldSeeder,
        DemoData::WorkPackageSeeder
      ]

      seeders.map { |seeder| seeder.new project, key }
    end

    def seed_settings
      welcome = translate_with_base_url("seeders.demo_data.welcome")

      if welcome.present?
        Setting.welcome_title = welcome[:title]
        Setting.welcome_text = welcome[:text]
        Setting.welcome_on_homescreen = 1
      end
    end

    def reset_project(key)
      delete_project(key)
      create_project(key)
    end

    def create_project(key)
      Project.create! project_data(key)
    end

    def delete_project(key)
      if delete_me = find_project(key)
        delete_me.destroy
      end
    end

    def set_members(project)
      role = Role.find_by(name: translate_with_base_url(:default_role_project_admin))
      user = User.admin.first

      Member.create!(
        project: project,
        user: user,
        roles: [role]
      )
    end

    def set_types(project, key)
      project.types.clear
      Array(translate_with_base_url("seeders.demo_data.projects.#{key}.types")).each do |type_name|
        type = Type.find_by(name: translate_with_base_url(type_name))
        project.types << type
      end
    end

    def seed_categories(project, key)
      Array(translate_with_base_url("seeders.demo_data.projects.#{key}.categories")).each do |cat_name|
        project.categories.create name: cat_name
      end
    end

    def seed_news(project, key)
      Array(translate_with_base_url("seeders.demo_data.projects.#{key}")[:news]).each do |news|
        News.create! project: project, title: news[:title], summary: news[:summary], description: news[:description]
      end
    end

    def seed_queries(project, key)
      Array(translate_with_base_url("seeders.demo_data.projects.#{key}")[:queries]).each do |config|
        QueryBuilder.new(config, project).create!
      end
    end

    def seed_versions(project, key)
      version_data = translate_with_base_url("seeders.demo_data.projects.#{key}.versions")

      return if version_data.is_a?(String) && version_data.start_with?("translation missing")

      version_data.each do |attributes|
        VersionBuilder.new(attributes, project).create!
      end
    end

    def seed_board(project)
      Board.create!(
        project: project,
        name: translate_with_base_url('seeders.demo_data.board.name'),
        description: translate_with_base_url('seeders.demo_data.board.description')
      )
    end

    module Data
      module_function

      def project_data(key)
        {
          name: project_name(key),
          identifier: project_identifier(key),
          description: project_description(key),
          enabled_module_names: project_modules(key),
          types: project_types
        }
      end

      def project_name(key)
        translate_with_base_url("seeders.demo_data.projects.#{key}.name")
      end

      def project_identifier(key)
        translate_with_base_url("seeders.demo_data.projects.#{key}.identifier")
      end

      def project_description(key)
        translate_with_base_url("seeders.demo_data.projects.#{key}.description")
      end

      def project_types
        Type.all
      end

      def project_modules(key)
        translate_with_base_url("seeders.demo_data.projects.#{key}.modules")
      end

      def find_project(key)
        Project.find_by(identifier: project_identifier(key))
      end
    end

    include Data
  end
end
