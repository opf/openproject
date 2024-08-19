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
require_module_spec_helper

RSpec.describe "Hide attachments", :js, :with_cuprite do
  let(:permissions) do
    %i(add_work_packages
       manage_files_in_project
       edit_project
       view_work_packages
       edit_work_packages
       view_file_links
       manage_file_links)
  end
  let(:project) { create(:project, deactivate_work_package_attachments: true) }
  let!(:current_user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:work_package) { create(:work_package, project:, description: "Initial description") }
  let(:attachment) { create(:attachment, container: work_package) }

  let(:storage) { create(:nextcloud_storage_configured, name: "My storage") }
  let!(:project_storage) { create(:project_storage, project:, storage:) }
  let(:storage_title_xpath) { '//span[text()="My storage"]' }

  describe "Project setting" do
    it "changes database value" do
      login_as current_user

      visit external_file_storages_project_settings_project_storages_path(project)
      click_on("Attachments")

      expect(page).to have_css("toggle-switch", text: "Off")
      expect(project.reload).to be_deactivate_work_package_attachments

      click_on(class: "ToggleSwitch-track")
      expect(page).to have_css("toggle-switch", text: "On")
      wait_for(page).to have_css('svg[data-target="toggle-switch.loadingSpinner"][hidden="hidden"]', visible: :hidden)
      expect(project.reload).not_to be_deactivate_work_package_attachments

      click_on(class: "ToggleSwitch-track")
      expect(page).to have_css("toggle-switch", text: "Off")
      wait_for(page).to have_css('svg[data-target="toggle-switch.loadingSpinner"][hidden="hidden"]', visible: :hidden)
      expect(project.reload).to be_deactivate_work_package_attachments
    end

    context "if Setting.show_work_package_attachments is false", with_settings: { show_work_package_attachments: false } do
      let(:project) { create(:project) }

      it "renders the toggle as off for project with not set deactivate_work_package_attachments" do
        expect(project.deactivate_work_package_attachments).to be_nil

        login_as current_user

        visit external_file_storages_project_settings_project_storages_path(project)
        click_on("Attachments")

        expect(page).to have_css("toggle-switch", text: "Off")
      end
    end

    context "if Setting.show_work_package_attachments is true", with_settings: { show_work_package_attachments: true } do
      let(:project) { create(:project) }

      it "renders the toggle as on for project with not set deactivate_work_package_attachments" do
        expect(project.deactivate_work_package_attachments).to be_nil

        login_as current_user

        visit external_file_storages_project_settings_project_storages_path(project)
        click_on("Attachments")

        expect(page).to have_css("toggle-switch", text: "On")
      end
    end
  end

  describe "OpenProject setting" do
    it "changes database value" do
      checkbox_label = "Show attachments in the files tab by default"

      login_as create(:admin)
      visit admin_settings_attachments_path

      expect(page).to have_checked_field(checkbox_label)

      uncheck(checkbox_label)
      click_on("Save")

      # Check db directly to avoid cache being used.
      expect(Setting.find_by(name: "show_work_package_attachments").value).to be_falsy
      expect(page).to have_unchecked_field(checkbox_label)

      check(checkbox_label)
      click_on("Save")

      expect(Setting.find_by(name: "show_work_package_attachments").value).to be_truthy
      expect(page).to have_checked_field(checkbox_label)
    end
  end

  describe "Work package files tab" do
    it "hides attachments section when required" do
      work_package
      attachment
      login_as current_user
      page = Pages::FullWorkPackage.new(work_package, project)
      page.visit_tab!(:files)

      # wait for storage title to appear. it means Files tab has been loaded.
      wait_for(page).to have_xpath(storage_title_xpath, wait: 35)

      expect(page).to have_no_css("op-attachments")
      expect(page).to have_no_text("ATTACHMENTS")
      expect(page).to have_no_text("Attach files")
      expect(page).to have_no_text("FILES (1)")
    end
  end

  describe "Work package creation form" do
    it "hides attachments section when required" do
      login_as current_user
      page = Pages::FullWorkPackageCreate.new(project:)
      page.visit!

      # wait for storage title to appear(op-attachments is in the same section usually)
      wait_for(page).to have_xpath(storage_title_xpath, wait: 35)

      expect(page).to have_no_css("op-attachments")
      expect(page).to have_no_text("ATTACHMENTS")
      expect(page).to have_no_text("Attach files")
    end
  end
end
