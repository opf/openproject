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

require "spec_helper"

RSpec.describe "Projects", "subitems settings", :js do
  let(:permissions) { %i[edit_project] }
  let(:subitems_settings_page) { Pages::Projects::Settings::Subitems.new(project) }

  shared_let(:project_template) do
    create(:project, name: "Project Template", templated: true, workspace_type: :project)
  end

  shared_let(:program_template) do
    create(:project, name: "Program Template", templated: true, workspace_type: :program)
  end

  shared_let(:portfolio_template) do
    create(:project, name: "Portfolio Template", templated: true, workspace_type: :portfolio)
  end

  current_user do
    create(:user,
           member_with_permissions: {
             project => permissions,
             project_template => %i[view_project],
             program_template => %i[view_project],
             portfolio_template => %i[view_project]
           })
  end

  describe "for a regular project" do
    let(:project) { create(:project, workspace_type: :project) }

    it "allows setting and unsetting project template" do
      subitems_settings_page.visit!

      subitems_settings_page.expect_selected_project_template(nil)
      subitems_settings_page.expect_no_program_template_field
      subitems_settings_page.expect_no_portfolio_template_field

      subitems_settings_page.select_project_template(project_template)
      subitems_settings_page.save
      expect_and_dismiss_flash(message: "Successful update")

      subitems_settings_page.expect_selected_project_template(project_template.name)
      expect(project.subproject_template_assignments.project.first&.template).to eq(project_template)
      subitems_settings_page.select_project_template(nil)
      subitems_settings_page.save
      expect_and_dismiss_flash(message: "Successful update")

      subitems_settings_page.expect_selected_project_template(nil)
      expect(project.subproject_template_assignments.project).to be_empty
    end

    it "only shows project templates in the dropdown" do
      subitems_settings_page.visit!

      expect(page).to have_select("project_template", with_options: [project_template.name])
      expect(page).to have_no_select("project_template", with_options: [program_template.name])
    end
  end

  describe "for a portfolio" do
    let(:project) { create(:project, workspace_type: :portfolio) }

    it "allows setting templates for both projects and programs but not for portfolios" do
      subitems_settings_page.visit!

      subitems_settings_page.expect_selected_project_template(nil)
      subitems_settings_page.expect_selected_program_template(nil)

      subitems_settings_page.select_project_template(project_template)
      subitems_settings_page.select_program_template(program_template)
      subitems_settings_page.save
      expect_and_dismiss_flash(message: "Successful update")

      subitems_settings_page.expect_selected_project_template(project_template.name)
      subitems_settings_page.expect_selected_program_template(program_template.name)

      expect(project.subproject_template_assignments.project.first&.template).to eq(project_template)
      expect(project.subproject_template_assignments.program.first&.template).to eq(program_template)
      subitems_settings_page.select_project_template(nil)
      subitems_settings_page.select_program_template(nil)
      subitems_settings_page.save
      expect_and_dismiss_flash(message: "Successful update")

      subitems_settings_page.expect_selected_project_template(nil)
      subitems_settings_page.expect_selected_program_template(nil)
      expect(project.subproject_template_assignments).to be_empty
    end

    it "shows project templates in project dropdown and program templates in program dropdown" do
      subitems_settings_page.visit!

      expect(page).to have_select("project_template", with_options: [project_template.name])
      expect(page).to have_no_select("project_template", with_options: [program_template.name, portfolio_template.name])

      expect(page).to have_select("program_template", with_options: [program_template.name])
      expect(page).to have_no_select("program_template", with_options: [project_template.name, portfolio_template.name])

      expect(page).to have_no_select("portfolio_template")
    end
  end

  describe "permissions" do
    let(:project) { create(:project) }

    context "when user does not have edit_project permission" do
      let(:permissions) { %i[view_work_packages] }

      it "does not show the subitems menu entry" do
        visit project_settings_general_path(project)

        expect(page).to have_text "You are not authorized to access this page."
      end
    end
  end
end
