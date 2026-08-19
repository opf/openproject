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

module DemoData
  class ProjectSeeder < Seeder
    attr_reader :project
    alias_method :project_data, :seed_data

    self.needs = WorkPackageSeeder.needs + [
      BasicData::ProjectRoleSeeder,
      BasicData::GlobalRoleSeeder,
      BasicData::ProjectPhaseDefinitionSeeder
    ]

    def seed_data!
      print_status " ↳ Creating project: #{project_data.lookup('name')}"

      self.project = reset_project
      set_members
      seed_news
      set_types
      seed_categories
      seed_versions
      seed_queries
      seed_project_content
    end

    # override to add additional seeders
    def project_content_seeder_classes
      [
        DemoData::ProjectPhaseSeeder,
        DemoData::WikiSeeder,
        DemoData::WorkPackageSeeder,
        DemoData::WorkPackageBoardSeeder,
        ::Meetings::DemoData::MeetingSeriesSeeder,
        ::Meetings::DemoData::MeetingAgendaItemsSeeder,
        ::Meetings::DemoData::MeetingParticipantsSeeder,
        ::Meetings::DemoData::MeetingSeriesFinalizerSeeder,
        ::Meetings::DemoData::MeetingOccurrencesSeeder
      ]
    end

    def all_required_references
      [:default_role_project_admin] + types_seed_data
    end

    private

    attr_writer :project

    def reset_project
      print_status "   -Creating/Resetting project"
      delete_project
      create_project
    end

    def delete_project
      project_to_delete = Project.find_by(identifier: project_data.lookup("identifier"))
      project_to_delete&.destroy
    end

    def create_project
      Project.create! project_attributes
    end

    def set_members
      print_status "   -Setting members."

      role = seed_data.find_reference(:default_role_project_admin)

      Member.create!(
        project:,
        principal: admin_user,
        roles: [role]
      )

      seed_additional_members
    end

    # Adds the members configured via the project's `members` seed data. A principal can be a
    # user (added directly) or a department (added as a group, with its users inheriting the role).
    # References may be missing when the departments were not (re-)seeded, in which case we skip them.
    def seed_additional_members
      project_data.each("members") do |member_data|
        principal = seed_data.find_reference(member_data["principal"], default: nil)
        next if principal.nil?

        role = seed_data.find_reference(member_data["role"])
        Member.create!(project:, principal:, roles: [role])

        inherit_group_roles(principal) if principal.is_a?(Group)
      end
    end

    def inherit_group_roles(group)
      Groups::CreateInheritedRolesService
        .new(group, current_user: admin_user)
        .call(user_ids: group.user_ids, project_ids: [project.id])
    end

    def set_types
      print_status "   -Assigning types."

      project.types = seed_data.find_references(types_seed_data)
    end

    def seed_categories
      print_status "   -Creating categories"

      Array(project_data.lookup("categories")).each do |cat_name|
        project.categories.create name: cat_name
      end
    end

    def seed_news
      print_status "   -Creating news."

      project_data.each("news") do |news|
        News.create!(project:,
                     author: admin_user,
                     title: news["title"],
                     summary: news["summary"],
                     description: news["description"])
      end
    end

    def seed_queries
      print_status "   -Creating queries."

      Array(project_data.lookup("queries")).each do |config|
        QueryBuilder.new(config, project:, user: admin_user, seed_data:).create!
      end
    end

    def seed_versions
      print_status "   -Creating versions."

      project_data.each("versions") do |attributes|
        VersionBuilder.new(attributes, project:, user: admin_user, seed_data:).create!
      end
    end

    def seed_project_content
      project_content_seeder_classes.each do |seeder_class|
        print_status "   -#{seeder_class.name.demodulize}"

        seeder = seeder_class.new(project, project_data)
        seeder.seed!
      end
    end

    def types_seed_data
      seed_data.lookup("types") || []
    end

    def project_attributes # rubocop:disable Metrics/AbcSize
      {
        name: project_data.lookup("name"),
        identifier: project_data.lookup("identifier"),
        status_code: project_data.lookup("status_code"),
        status_explanation: project_data.lookup("status_explanation"),
        description: project_data.lookup("description"),
        enabled_module_names: project_data.lookup("modules"),
        types: Type.all,
        parent: Project.find_by(identifier: project_data.lookup("parent")),
        workspace_type: "project"
      }
    end
  end
end
