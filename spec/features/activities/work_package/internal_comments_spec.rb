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

RSpec.describe "Work package internal comments",
               :js,
               with_ee: [:internal_comments] do
  include InternalCommentsHelpers

  shared_let(:project) { create(:project, enabled_internal_comments: true) }
  shared_let(:admin) { create(:admin) }
  shared_let(:viewer) { create_user_with_internal_comments_view_permissions }
  shared_let(:viewer_with_commenting_permission) { create_user_with_internal_comments_view_and_write_permissions }
  shared_let(:project_admin) { create_user_as_project_admin }

  shared_let(:work_package) { create(:work_package, project:, author: admin) }
  shared_let(:first_comment) do
    create(:work_package_journal, user: admin, notes: "A (internal) comment by admin",
                                  journable: work_package, version: 2, internal: true)
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  context "with an admin user" do
    current_user { admin }

    shared_examples "internal comments are disabled" do
      it "does not allow adding an internal comment" do
        activity_tab.expect_input_field

        activity_tab.type_comment("This comment cannot be internal")
      end
    end

    context "when the feature is enabled for the project" do
      before do
        wp_page.visit!
        wp_page.wait_for_activity_tab
      end

      it "allows adding an internal comment" do
        activity_tab.expect_input_field

        activity_tab.add_comment(text: "First (internal) comment by admin", internal: true)

        activity_tab.expect_journal_notes(text: "First (internal) comment by admin")
      end
    end

    context "when the feature is not enabled for the project" do
      before do
        project.enabled_internal_comments = false
        project.save!

        wp_page.visit!
        wp_page.wait_for_activity_tab
      end

      it_behaves_like "internal comments are disabled"
    end

    context "when the enterprise plan does not allow internal comments", with_ee: [] do
      before do
        project.enabled_internal_comments = true
        project.save!

        wp_page.visit!
        wp_page.wait_for_activity_tab
      end

      it_behaves_like "internal comments are disabled"
    end
  end

  context "with a user that is only allowed to view internal comments" do
    current_user { viewer }

    before do
      first_comment

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "does show internal comments but does NOT enable editing or quoting comments" do
      activity_tab.expect_journal_notes(text: "A (internal) comment by admin")

      activity_tab.within_journal_entry(first_comment) do
        page.find_test_selector("op-wp-journal-#{first_comment.id}-action-menu").click

        expect(page).not_to have_test_selector("op-wp-journal-#{first_comment.id}-edit")
        expect(page).not_to have_test_selector("op-wp-journal-#{first_comment.id}-quote")
      end
    end
  end

  context "with a user that is allowed to view, create and edit own comments" do
    current_user { viewer_with_commenting_permission }

    before do
      first_comment

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "allows adding a internal comment" do
      activity_tab.expect_input_field

      activity_tab.add_comment(text: "First (internal) comment by member", internal: true)

      activity_tab.expect_journal_notes(text: "First (internal) comment by member")

      created_comment = work_package.journals.reload.last

      activity_tab.within_journal_entry(created_comment) do
        page.find_test_selector("op-wp-journal-#{created_comment.id}-action-menu").click
        page.find_test_selector("op-wp-journal-#{created_comment.id}-edit").click

        page.within_test_selector("op-work-package-journal-form-element") do
          expect(page).not_to have_test_selector("op-work-package-journal-internal-comment-checkbox")
          activity_tab.get_editor_form_field_element.set_value("Edited comment by member")
          page.find_test_selector("op-submit-work-package-journal-form").click
        end

        wait_for { page }.to have_test_selector("op-journal-notes-body", text: "Edited comment by member")
      end
    end

    it "does show internal comments but does NOT enable editing other users comments" do
      activity_tab.expect_journal_notes(text: "A (internal) comment by admin")

      activity_tab.within_journal_entry(first_comment) do
        page.find_test_selector("op-wp-journal-#{first_comment.id}-action-menu").click

        # not allowed to edit other user's internal comments
        expect(page).not_to have_test_selector("op-wp-journal-#{first_comment.id}-edit")
        # allowed to quote other user's comments
        expect(page).to have_test_selector("op-wp-journal-#{first_comment.id}-quote")
      end
    end
  end

  context "with a user that is allowed to view, create and edit all comments" do
    current_user { project_admin }

    let(:external_comment) do
      create(:work_package_journal,
             user: project_admin, notes: "An external comment by member",
             journable: work_package, version: (work_package.journals.reload.last.version + 1), internal: false)
    end

    before do
      first_comment
      external_comment

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "allows editing and quoting internal comments" do
      activity_tab.expect_journal_notes(text: "A (internal) comment by admin")

      activity_tab.edit_comment(first_comment, text: "A (internal) comment by admin - EDITED")

      activity_tab.within_journal_entry(first_comment) do
        activity_tab.expect_journal_notes(text: "A (internal) comment by admin - EDITED")
      end

      activity_tab.quote_comment(first_comment)
      page.within_test_selector("op-work-package-journal-form-element") do
        expect(page).to have_checked_field("Internal comment")
      end

      activity_tab.quote_comment(external_comment)
      page.within_test_selector("op-work-package-journal-form-element") do
        expect(page).to have_checked_field("Internal comment")
      end
    end
  end

  describe "inline banner", with_ee: [] do
    current_user { project_admin }

    before do
      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "shows the banner" do
      activity_tab.open_new_comment_editor

      expect(page).to have_test_selector("op-enterprise-banner", text: "Write internal comments only a small group can see")
    end
  end

  describe "mentioning users in comments" do
    current_user { project_admin }

    shared_let(:user_without_internal_comments_view_permissions) do
      create_user_without_internal_comments_view_permissions
    end

    shared_let(:group) { create(:group, firstname: "A", lastname: "Group") }
    shared_let(:group_member) do
      group_role = create(:project_role)
      create(:member,
             principal: group,
             project:,
             roles: [group_role])
    end

    before do
      wp_page.visit!
      wait_for_reload
      expect_angular_frontend_initialized
      wp_page.wait_for_activity_tab
    end

    context "with internal comments initially enabled" do
      it "restricts mentions to project members with view internal comments permission" do
        activity_tab.open_new_comment_editor
        expect(page).to have_test_selector("op-work-package-journal-form-element")

        activity_tab.check_internal_comment_checkbox
        activity_tab.refocus_editor
        activity_tab.type_comment("@")

        expect(page.all(".mention-list-item").map(&:text))
          .to contain_exactly("Project Admin", "Internal Viewer", "Internal ViewerCommenter")
      end
    end

    context "with internal comments initially disabled" do
      it "allows mentioning project members but they are sanitized when the checkbox is checked" do
        activity_tab.type_comment("@")

        expect(page.all(".mention-list-item").map(&:text))
          .to contain_exactly("A Viewer", "Group", "Project Admin", "Internal Viewer", "Internal ViewerCommenter")

        page.find(".mention-list-item", text: "A Viewer").click
        activity_tab.type_comment("@Internal")
        page.first(".mention-list-item", text: "Internal Viewer").click
        activity_tab.type_comment("@Group")
        page.find(".mention-list-item", text: "Group").click

        activity_tab.check_internal_comment_checkbox

        page.within_test_selector("op-work-package-journal-form-element") do
          expect(page.all("a.mention").map(&:text))
            .to contain_exactly("@Internal Viewer")

          expect(page).to have_text("@A Viewer") & have_text("@Group")
        end
      end
    end

    context "when editing a internal comment" do
      it "honors mentionable principals" do
        activity_tab.within_journal_entry(first_comment) do
          page.find_test_selector("op-wp-journal-#{first_comment.id}-action-menu").click
          page.find_test_selector("op-wp-journal-#{first_comment.id}-edit").click

          activity_tab.type_comment(" @")
        end

        expect(page.all(".mention-list-item").map(&:text))
            .to contain_exactly("Project Admin", "Internal Viewer", "Internal ViewerCommenter")
      end
    end

    context "with a server error" do
      before do
        allow(WorkPackages::ActivitiesTab::InternalCommentMentionsSanitizer).to receive(:sanitize)
          .and_raise(RuntimeError, "Something went wrong!!!")
      end

      it "shows an error message" do
        activity_tab.type_comment("@Internal")
        page.first(".mention-list-item", text: "Internal Viewer").click

        activity_tab.check_internal_comment_checkbox

        page.within_test_selector("op-primer-flash-message") do
          expect(page).to have_text("Something went wrong!!!")
        end
      end
    end
  end

  describe "internal comment checkbox state persistence" do
    current_user { project_admin }

    let(:second_work_package) { create(:work_package, project:, author: admin) }
    let(:second_wp_page) { Pages::FullWorkPackage.new(second_work_package, project) }

    before do
      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "persists checkbox state when switching between work package tabs" do
      activity_tab.open_new_comment_editor
      activity_tab.check_internal_comment_checkbox
      activity_tab.expect_internal_comment_checked

      wp_page.switch_to_tab tab: "relations"
      wp_page.switch_to_tab tab: "activity"
      wp_page.wait_for_activity_tab

      activity_tab.open_new_comment_editor
      activity_tab.expect_internal_comment_checked
    end

    it "isolates checkbox state between different work packages" do
      activity_tab.open_new_comment_editor
      activity_tab.check_internal_comment_checkbox
      activity_tab.expect_internal_comment_checked

      second_wp_page.visit!
      second_wp_page.wait_for_activity_tab

      second_wp_activity_tab = Components::WorkPackages::Activities.new(second_work_package)
      second_wp_activity_tab.open_new_comment_editor
      second_wp_activity_tab.expect_internal_comment_unchecked

      wp_page.visit!
      wp_page.wait_for_activity_tab

      activity_tab.open_new_comment_editor
      activity_tab.expect_internal_comment_checked
    end

    it "handles localStorage errors gracefully" do
      page.execute_script(<<~JS)
        localStorage.setItem = function() {
          throw new Error('Storage quota exceeded');
        };
      JS

      activity_tab.open_new_comment_editor
      activity_tab.check_internal_comment_checkbox
      activity_tab.expect_internal_comment_checked

      page.execute_script(<<~JS)
        localStorage.setItem = Storage.prototype.setItem;
      JS
    end
  end

  describe "making internal comments public" do
    current_user { project_admin }

    before do
      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    context "when the user unchecks the 'internal comment' checkbox" do
      it "asks for explicit confirmation from the user" do
        activity_tab.open_new_comment_editor

        aggregate_failures "empty comments do not ask for confirmation" do
          activity_tab.check_internal_comment_checkbox
          activity_tab.uncheck_internal_comment_checkbox

          activity_tab.expect_internal_comment_unchecked
          expect(page).not_to have_test_selector("op-work-package-internal-comment-confirmation-dialog")
        end

        activity_tab.check_internal_comment_checkbox
        activity_tab.refocus_editor
        activity_tab.type_comment("This is an internal comment")

        aggregate_failures "non-empty comments ask for confirmation, cancel retains current state" do
          activity_tab.uncheck_internal_comment_checkbox
          activity_tab.expect_internal_comment_confirmation_dialog do
            click_on "Cancel"
          end
          activity_tab.expect_internal_comment_checked
        end

        aggregate_failures "non-empty comments ask for confirmation, confirm changes the state" do
          activity_tab.uncheck_internal_comment_checkbox

          activity_tab.expect_internal_comment_confirmation_dialog do
            click_on "Make public"
          end

          activity_tab.expect_internal_comment_unchecked
        end
      end
    end

    context "when the user goes through multiple confirmations" do
      it "retains the correct state" do
        activity_tab.open_new_comment_editor
        activity_tab.type_comment("This is an internal comment")
        activity_tab.check_internal_comment_checkbox

        aggregate_failures "check and confirm" do
          activity_tab.uncheck_internal_comment_checkbox

          activity_tab.expect_internal_comment_confirmation_dialog do
            click_on "Make public"
          end
          activity_tab.expect_internal_comment_unchecked
        end

        aggregate_failures "check, uncheck then cancel" do
          activity_tab.check_internal_comment_checkbox
          activity_tab.uncheck_internal_comment_checkbox

          activity_tab.expect_internal_comment_confirmation_dialog do
            click_on "Cancel"
          end
          activity_tab.expect_internal_comment_checked
        end
      end
    end
  end
end
