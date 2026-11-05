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

module UserGuideData
  class ProjectSeeder < Seeder
    IDENTIFIER = "user-guide"
    CONTENT_FILE = Rails.root.join("app/seeders/user_guide_data/project.yml")

    def seed_data!
      print_status " ↳ Creating the user guide project..."

      project = Project.create!(name: project_data["name"],
                                identifier: IDENTIFIER,
                                workspace_type: "project",
                                enabled_module_names: project_data["modules"],
                                project_types: Type.all.map { ProjectType.new(type: it) })
      project_data["members"].each { add_member(project, it) }
    end

    def applicable?
      Project.where(identifier: IDENTIFIER).none?
    end

    private

    def project_data
      @project_data ||= YAML.load_file(CONTENT_FILE).fetch("project")
    end

    def add_member(project, data)
      Member.create!(project:,
                     principal: User.find_by!(login: data["login"]),
                     roles: [seed_data.find_reference(:"default_role_#{data['role']}")])
    end
  end
end
