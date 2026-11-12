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

module Pages
  module Projects
    module Settings
      class Subitems < ::Pages::Page
        attr_reader :project

        def initialize(project)
          super()
          @project = project
        end

        def path
          project_settings_subitems_path(project)
        end

        def select_project_template(template)
          select_template("project_template", template)
        end

        def select_program_template(template)
          select_template("program_template", template)
        end

        def expect_selected_project_template(template_name)
          expect_selected_template("project_template", template_name)
        end

        def expect_selected_program_template(template_name)
          expect_selected_template("program_template", template_name)
        end

        def expect_no_program_template_field
          expect(page).to have_no_select("program_template")
        end

        def expect_no_portfolio_template_field
          expect(page).to have_no_select("portfolio_template")
        end

        def save
          click_button "Save"
        end

        private

        def select_template(field_name, template)
          if template.nil?
            select "No predefined template", from: field_name
          else
            select template.name, from: field_name
          end
        end

        def expect_selected_template(field_name, template_name)
          if template_name.nil?
            expect(page).to have_select(field_name, selected: "No predefined template")
          else
            expect(page).to have_select(field_name, selected: template_name)
          end
        end
      end
    end
  end
end
