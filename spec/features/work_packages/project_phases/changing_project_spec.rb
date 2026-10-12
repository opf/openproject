# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Linked projects phases and work packages when changing the project", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:phase_definition_active_in_both_projects) { create(:project_phase_definition) }
  shared_let(:phase_definition_active_in_source_project) { create(:project_phase_definition) }
  shared_let(:source_project) { create(:project) }
  shared_let(:target_project) { create(:project) }
  shared_let(:phase_active_in_both_projects_source) do
    create(:project_phase, project: source_project, definition: phase_definition_active_in_both_projects)
  end
  shared_let(:phase_active_in_both_projects_target) do
    create(:project_phase, project: target_project, definition: phase_definition_active_in_both_projects)
  end
  shared_let(:phase_active_in_source_project) do
    create(:project_phase, project: source_project, definition: phase_definition_active_in_source_project)
  end
  shared_let(:work_package) do
    create(:work_package,
           project: source_project)
  end
  shared_let(:role) do
    create(:project_role, permissions: %i[view_project_phases view_work_packages edit_work_packages move_work_packages])
  end
  shared_let(:user) do
    create(:user,
           member_with_roles: { source_project => role, target_project => role })
  end
  current_user { user }

  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }

  context "when the project phase is active in both projects" do
    before do
      work_package.project_phase_definition = phase_definition_active_in_both_projects
      work_package.save
    end

    it "leaves the project phase unchanged" do
      work_package_page.visit!
      work_package_page.select_from_context_menu("Move to another project")

      select_autocomplete page.find_test_selector("new_project_id"),
                          query: target_project.name,
                          select_text: target_project.name,
                          results_selector: "body"

      wait_for_network_idle

      page.document.synchronize do
        submitted = page.evaluate_script(<<~JS)
          (() => {
            const button = document.querySelector("[name='follow']");
            button?.click();
            return Boolean(button);
          })()
        JS
        raise Capybara::ElementNotFound unless submitted
      end
      page.document.synchronize(30) do
        moved = work_package.reload.project == target_project
        raise Capybara::ElementNotFound unless moved && page.current_path.include?("/work_packages/#{work_package.id}")
      end

      work_package_page.expect_attributes(project_phase: phase_definition_active_in_both_projects.name)
    end
  end

  context "when the project phase is only active in the source project" do
    before do
      work_package.project_phase_definition = phase_definition_active_in_source_project
      work_package.save
    end

    it "removes the project phase" do
      work_package_page.visit!
      work_package_page.select_from_context_menu("Move to another project")

      select_autocomplete page.find_test_selector("new_project_id"),
                          query: target_project.name,
                          select_text: target_project.name,
                          results_selector: "body"

      wait_for_network_idle

      page.document.synchronize do
        submitted = page.evaluate_script(<<~JS)
          (() => {
            const button = document.querySelector("[name='follow']");
            button?.click();
            return Boolean(button);
          })()
        JS
        raise Capybara::ElementNotFound unless submitted
      end
      page.document.synchronize(30) do
        moved = work_package.reload.project == target_project
        raise Capybara::ElementNotFound unless moved && page.current_path.include?("/work_packages/#{work_package.id}")
      end

      work_package_page.expect_attributes(project_phase: nil)
    end
  end
end
