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
#++

require "spec_helper"
require_relative "../../support/pages/projects/settings/backlogs"

RSpec.describe "Backlogs Project Settings", :js do
  let!(:closed_status)      { create(:status, name: "Closed", is_closed: true) }
  let!(:closed_like_status) { create(:status, name: "Sorta kinda Finished", is_default: true) }
  let!(:type_story) { create(:type_feature, name: "Story") }
  let!(:type_task)  { create(:type_task, name: "Task") }
  let!(:project) do
    create(:project,
           enabled_module_names: %w(backlogs),
           types: [type_story, type_task])
  end
  let(:role) do
    create(:project_role,
           permissions: %i[select_backlog_types_and_statuses])
  end
  let!(:current_user) do
    create(:user,
           member_with_roles: { project => role })
  end
  let(:settings_page) { Pages::Projects::Settings::Backlogs.new(project) }
  let(:done_status_ids_autocompleter) { FormFields::Primerized::AutocompleteField.new("story_types", selector: "[data-test-selector='done_status_ids_autocomplete']") }
  let(:excluded_type_ids_autocompleter) { FormFields::Primerized::AutocompleteField.new("excluded_types", selector: "[data-test-selector='backlog_excluded_type_ids_autocomplete']") }

  before do
    login_as current_user
  end

  context "when navigating between tabs" do
    let(:role) do
      create(:project_role,
             permissions: %i[select_backlog_types_and_statuses share_sprint])
    end

    it "persists the active tab in the URL when switching tabs" do
      settings_page.visit!

      expect(page).to have_heading "Backlogs"

      expect(page).to have_current_path(project_settings_backlogs_path(project))

      click_link I18n.t("backlogs.sharing")

      expect(page).to have_current_path(project_settings_backlog_sharing_path(project))

      page.refresh

      expect(page).to have_current_path(project_settings_backlog_sharing_path(project))

      click_link I18n.t("backlogs.types_and_statuses")

      expect(page).to have_current_path(project_settings_backlogs_path(project))
    end
  end

  it "allows setting a status as done although it is not closed" do
    settings_page.visit!

    expect(page).to have_heading "Backlogs"

    wait_for_network_idle
    wait_for_autocompleter_options_to_be_loaded

    # Closed is preselected when the module is enabled, since it has the `is_closed: true` attribute
    done_status_ids_autocompleter.expect_selected "Closed"
    done_status_ids_autocompleter.open_options
    # It cannot be disabled
    done_status_ids_autocompleter.expect_disabled "Closed"

    done_status_ids_autocompleter.select_option "Sorta kinda Finished"

    done_status_ids_autocompleter.expect_selected "Closed"
    done_status_ids_autocompleter.expect_selected "Sorta kinda Finished"
    done_status_ids_autocompleter.expect_not_disabled "Definition of Done"

    done_status_ids_autocompleter.close_autocompleter

    click_button "Save"

    expect_flash(type: :success, message: "Successful update")

    wait_for_network_idle
    wait_for_autocompleter_options_to_be_loaded

    done_status_ids_autocompleter.expect_selected "Closed"
    done_status_ids_autocompleter.expect_selected "Sorta kinda Finished"

    done_status_ids_autocompleter.deselect_option "Sorta kinda Finished"

    click_button "Save"

    wait_for_network_idle
    wait_for_autocompleter_options_to_be_loaded

    expect_flash(type: :success, message: "Successful update")

    done_status_ids_autocompleter.expect_selected "Closed"
    done_status_ids_autocompleter.expect_not_selected "Sorta kinda Finished"
  end

  it "allows excluding work package types from the backlog" do
    settings_page.visit!

    expect(page).to have_heading "Backlogs"

    wait_for_network_idle
    wait_for_autocompleter_options_to_be_loaded

    # No types are excluded by default
    excluded_type_ids_autocompleter.expect_not_selected "Task"

    excluded_type_ids_autocompleter.select_option "Task"
    excluded_type_ids_autocompleter.expect_selected "Task"

    excluded_type_ids_autocompleter.close_autocompleter

    click_button "Save"

    expect_flash(type: :success, message: "Successful update")

    wait_for_network_idle
    wait_for_autocompleter_options_to_be_loaded

    # After save, Task should still be selected
    excluded_type_ids_autocompleter.expect_selected "Task"

    # Deselect the type and save again
    excluded_type_ids_autocompleter.deselect_option "Task"
    click_button "Save"

    wait_for_network_idle
    wait_for_autocompleter_options_to_be_loaded

    expect_and_dismiss_flash(type: :success, message: "Successful update")

    excluded_type_ids_autocompleter.expect_not_selected "Task"
  end
end
