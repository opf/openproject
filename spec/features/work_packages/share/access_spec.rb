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

RSpec.describe "Shared Work Package Access",
               :js, :with_cuprite,
               with_ee: %i[work_package_sharing] do
  shared_let(:project) { create(:project_with_types) }
  # This custom field is not explicitly displayed, but it's purpose is to ensure there are no errors
  # on the overview page while displaying project attributes.
  shared_let(:int_project_custom_field) { create(:integer_project_custom_field, projects: [project]) }
  shared_let(:work_package) { create(:work_package, project:, journal_notes: "Hello!") }
  shared_let(:sharer) { create(:admin) }
  shared_let(:shared_with_user) { create(:user, firstname: "Mean", lastname: "Turkey") }

  shared_let(:viewer_role) { create(:view_work_package_role) }
  shared_let(:commenter_role) { create(:comment_work_package_role) }
  shared_let(:editor_role) { create(:edit_work_package_role) }

  let(:projects_page) { Pages::Projects::Index.new }
  let(:project_page) { Pages::Projects::Show.new(project) }
  let(:projects_top_menu) { Components::Projects::TopMenu.new }
  let(:global_work_packages_page) { Pages::WorkPackagesTable.new }
  let(:work_packages_page) { Pages::WorkPackagesTable.new(project) }
  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
  let(:share_modal) { Components::Sharing::WorkPackages::ShareModal.new(work_package) }
  let(:add_comment_button_selector) { ".work-packages--activity--add-comment" }
  let(:attach_files_button_selector) { "op-attachments--upload-button" }

  specify "'View' role share access" do
    using_session "sharer" do
      # Sharing the Work Package with "View" access
      login_as(sharer)

      work_package_page.visit!
      work_package_page.click_share_button
      share_modal.expect_open

      share_modal.invite_user!(shared_with_user, "View")

      share_modal.close

      # Shared-with users with the "View" role CAN'T become assignees
      assignee_field = work_package_page.edit_field(:assignee)
      assignee_field.activate!
      results = assignee_field.autocomplete("Mean Turkey", select: false)
      wait_for_network_idle
      expect(results)
        .to have_no_css(".ng-option", text: "Mean Turkey", wait: 0)
      assignee_field.cancel_by_escape
    end

    using_session "shared-with user" do
      login_as(shared_with_user)
      # Work Package's project is now listed
      # 1. Via the Projects Index Page
      projects_page.visit!
      projects_page.expect_projects_listed(project)

      # 2. Via the Projects dropdown in the top menu
      projects_top_menu.toggle!
      projects_top_menu.expect_result(project.name)
      # 3. Visiting the Project's URL directly
      project_page.visit!

      # The project overview page is loaded without errors
      wait_for_network_idle
      project_page.expect_no_toaster(type: "error")

      #
      # Work Package is now visible
      project_page.within_sidebar do
        click_link(I18n.t("label_work_package_plural"))
      end
      work_packages_page.expect_work_package_listed(work_package)
      work_package_page.visit!
      work_package_page.ensure_loaded

      # Every field however is read-only
      %i[type subject description
         assignee responsible
         estimatedTime remainingTime
         combinedDate category version
         overallCosts laborCosts].each do |field|
        work_package_page.edit_field(field).expect_read_only
      end

      work_package_page.ensure_page_loaded # waits for activity section to be ready
      work_package_page.within_active_tab do
        # Commenting is disabled
        expect(page)
          .to have_no_css(add_comment_button_selector)
      end

      # And so is viewing and uploading attachments
      work_package_page.switch_to_tab(tab: "Files")
      work_package_page.expect_tab("Files")
      work_package_page.within_active_tab do
        expect(page)
          .not_to have_test_selector(attach_files_button_selector)
      end
    end
  end

  specify "'Comment' role share access" do
    using_session "sharer" do
      # Sharing the Work Package with "View" access
      login_as(sharer)

      work_package_page.visit!
      work_package_page.click_share_button
      share_modal.expect_open

      share_modal.invite_user!(shared_with_user, "Comment")
      share_modal.close

      # TODO: This is currently expected failing behavior.
      # Will be fixed in #51551
      # Shared-with users with the "Comment" role CAN become assignees
      #
      # assignee_field = work_package_page.edit_field(:assignee)
      # assignee_field.activate!
      # results = assignee_field.autocomplete('Mean Turkey', select: false)
      # wait_for_network_idle
      # expect(results)
      #   .to have_css('.ng-option', text: 'Mean Turkey', wait: 0)
      # assignee_field.cancel_by_escape
    end

    using_session "shared-with user" do
      login_as(shared_with_user)
      # Work Package's project is now listed
      # 1. Via the Projects Index Page
      projects_page.visit!
      projects_page.expect_projects_listed(project)

      # 2. Via the Projects dropdown in the top menu
      projects_top_menu.toggle!
      projects_top_menu.expect_result(project.name)

      # 3. Visiting the Project's URL directly
      project_page.visit!

      # The project overview page is loaded without errors
      wait_for_network_idle
      project_page.expect_no_toaster(type: "error")

      #
      # Work Package is now visible
      project_page.within_sidebar do
        click_link(I18n.t("label_work_package_plural"))
      end
      work_packages_page.expect_work_package_listed(work_package)
      work_package_page.visit!
      work_package_page.ensure_loaded

      # Every field however is read-only
      %i[type subject description
         assignee responsible
         estimatedTime remainingTime
         combinedDate category version
         overallCosts laborCosts].each do |field|
        work_package_page.edit_field(field).expect_read_only
      end

      # Spent time is visible and loggable
      SpentTimeEditField.new(page, "spentTime")
                        .time_log_icon_visible(true)

      work_package_page.ensure_page_loaded # waits for activity section to be ready
      work_package_page.within_active_tab do
        # Commenting is enabled
        expect(page)
          .to have_css(add_comment_button_selector)
      end

      # Attachments are uploadable
      work_package_page.switch_to_tab(tab: "Files")
      work_package_page.expect_tab("Files")
      work_package_page.within_active_tab do
        expect(page)
          .to have_test_selector(attach_files_button_selector)
      end
    end
  end

  specify "'Edit' role share access" do
    using_session "sharer" do
      # Sharing the Work Package with "View" access
      login_as(sharer)

      work_package_page.visit!
      work_package_page.click_share_button
      share_modal.expect_open

      share_modal.invite_user!(shared_with_user, "Edit")

      share_modal.close

      # TODO: This is currently expected failing behavior.
      # Will be fixed in #51551
      # Shared-with users with the "Edit" role CAN become assignees
      #
      # assignee_field = work_package_page.edit_field(:assignee)
      # assignee_field.activate!
      # results = assignee_field.autocomplete('Mean Turkey', select: false)
      # wait_for_network_idle
      # expect(results)
      #   .to have_css('.ng-option', text: 'Mean Turkey', wait: 0)
      # assignee_field.cancel_by_escape
    end

    using_session "shared-with user" do
      login_as(shared_with_user)
      # Work Package's project is now listed
      # 1. Via the Projects Index Page
      projects_page.visit!
      projects_page.expect_projects_listed(project)

      # 2. Via the Projects dropdown in the top menu
      projects_top_menu.toggle!
      projects_top_menu.expect_result(project.name)

      # 3. Visiting the Project's URL directly
      project_page.visit!

      # The project overview page is loaded without errors
      wait_for_network_idle
      project_page.expect_no_toaster(type: "error")

      #
      # Work Package is now visible
      project_page.within_sidebar do
        click_link(I18n.t("label_work_package_plural"))
      end
      work_packages_page.expect_work_package_listed(work_package)
      work_package_page.visit!
      work_package_page.ensure_loaded

      # Every field however is editable
      %i[type subject description
         assignee responsible
         estimatedTime remainingTime
         combinedDate category].each do |field|
        expect(work_package_page.edit_field(field))
          .to be_editable
      end
      # Except for
      %i[version
         overallCosts laborCosts].each do |field|
        work_package_page.edit_field(field).expect_read_only
      end

      # Spent time is visible and loggable
      SpentTimeEditField.new(page, "spentTime")
                        .time_log_icon_visible(true)

      work_package_page.ensure_page_loaded # waits for activity section to be ready
      work_package_page.within_active_tab do
        # Commenting is enabled
        expect(page)
          .to have_css(add_comment_button_selector)
      end

      # Attachments are uploadable
      work_package_page.switch_to_tab(tab: "Files")
      work_package_page.expect_tab("Files")
      work_package_page.within_active_tab do
        expect(page)
          .to have_test_selector(attach_files_button_selector)
      end
    end
  end
end
