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

RSpec.describe "Copying a work package with linked project phases", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:phase_definition) { create(:project_phase_definition) }
  shared_let(:source_project) { create(:project) }
  shared_let(:target_project) { create(:project) }
  shared_let(:source_phase) { create(:project_phase, project: source_project, definition: phase_definition) }
  shared_let(:target_phase) { create(:project_phase, project: target_project, definition: phase_definition) }
  shared_let(:work_package) { create(:work_package, project: source_project, project_phase_definition: phase_definition) }
  shared_let(:role) do
    create(:project_role,
           permissions: %i[view_project_phases
                           view_work_packages
                           edit_work_packages
                           copy_work_packages
                           add_work_packages])
  end
  shared_let(:user) do
    create(:user,
           member_with_roles: { source_project => role, target_project => role })
  end

  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }

  current_user { user }

  def submit_copy(button_text)
    submit_button = find_button(button_text)
    page.execute_script("arguments[0].click()", submit_button)

    copied_work_package_id = nil
    page.document.synchronize(20) do
      copied_work_package_id = page.current_path[%r{/work_packages/(\d+)}, 1]&.to_i
      raise Capybara::ElementNotFound if copied_work_package_id.nil? || copied_work_package_id == work_package.id
    end

    WorkPackage.find(copied_work_package_id)
  end

  context "when duplicating within the same project" do
    it "keeps the linked project phase" do
      work_package_page.visit!

      work_package_page.select_from_context_menu("Duplicate")

      copied_work_package = submit_copy(I18n.t("js.button_save"))

      expect(copied_work_package.project).to eq(source_project)
      expect(copied_work_package.project_phase_definition).to eq(phase_definition)
      work_package_page.expect_attributes(project_phase: phase_definition.name)
    end
  end

  context "when the target project has the linked definition active" do
    it "copies the work package including the linked project phase" do
      work_package_page.visit!

      work_package_page.select_from_context_menu("Duplicate in another project")

      select_autocomplete page.find_test_selector("new_project_id"),
                          query: target_project.name,
                          select_text: target_project.name,
                          results_selector: "body"

      wait_for_network_idle

      copied_work_package = submit_copy("Duplicate and follow")

      expect(copied_work_package.project).to eq(target_project)
      expect(copied_work_package.project_phase_definition).to eq(phase_definition)
      work_package_page.expect_attributes(project_phase: phase_definition.name)
    end
  end

  context "when the target project does not have the linked definition active" do
    before do
      target_phase.update!(active: false)
    end

    it "copies the work package but not the link to the inactive phase" do
      work_package_page.visit!

      work_package_page.select_from_context_menu("Duplicate in another project")

      select_autocomplete page.find_test_selector("new_project_id"),
                          query: target_project.name,
                          select_text: target_project.name,
                          results_selector: "body"

      wait_for_network_idle

      copied_work_package = submit_copy("Duplicate and follow")

      expect(copied_work_package.project).to eq(target_project)
      work_package_page.expect_no_attribute("projectPhase")

      # Since the phase is deactivated, it is not displayed as linked. But in the database, the value is attached.
      expect(copied_work_package.project_phase_definition).to eq(phase_definition)
    end
  end
end
