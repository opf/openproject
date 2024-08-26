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
require_relative "../support/pages/work_package_gitlab_tab"

RSpec.describe "Open the Gitlab tab", :js do
  let(:user) { create(:user, member_with_roles: { project => role }) }

  let(:role) do
    create(:project_role,
           permissions: %i(view_work_packages
                           add_work_package_notes
                           show_gitlab_content))
  end

  let(:project) do
    create(:project,
           enabled_module_names: %i[work_package_tracking gitlab])
  end

  let(:work_package) { create(:work_package, project:, subject: "A test work_package") }

  let(:tabs) { Components::WorkPackages::Tabs.new(work_package) }
  let(:gitlab_tab_element) { find(".op-tab-row--link_selected", text: "GITLAB") }
  let(:gitlab_tab) { Pages::GitlabTab.new(work_package.id) }

  let(:issue) { create(:gitlab_issue, :open, work_packages: [work_package], title: "A Test Issue title") }
  let(:merge_request) { create(:gitlab_merge_request, :open, work_packages: [work_package], title: "A Test MR title") }

  let(:pipeline) do
    create(:gitlab_pipeline, gitlab_merge_request: merge_request, name: "a pipeline name")
  end

  shared_examples_for "a gitlab tab" do
    before do
      issue
      pipeline
      login_as(user)
    end

    # compares the clipboard content by drafting a new comment, pressing ctrl+v and
    # comparing the pasted content against the provided text
    def expect_clipboard_content(text)
      work_package_page.switch_to_tab(tab: "activity")

      work_package_page.trigger_edit_comment
      work_package_page.update_comment(" ") # ensure the comment editor is fully loaded
      gitlab_tab.paste_clipboard_content
      expect(work_package_page.add_comment_container).to have_content(text)

      work_package_page.switch_to_tab(tab: "gitlab")
    end

    context "when the user is allowed to see the gitlab tab" do
      before do
        work_package_page.visit!
        work_package_page.switch_to_tab(tab: "gitlab")
      end

      it "shows the issues and merge requests associated with the work package" do
        tabs.expect_counter(gitlab_tab_element, 2)

        expect(page).to have_text("A Test Issue title")
        expect(page).to have_text("Open")

        expect(page).to have_text("A Test MR title")
        expect(page).to have_text("Pending")
      end

      it "allows the user to copy the branch name to the clipboard" do
        gitlab_tab.git_actions_menu_button.click
        gitlab_tab.git_actions_copy_branch_name_button.click

        expect(page).to have_text("Copied!")
        expect_clipboard_content("#{work_package.type.name.downcase}/#{work_package.id}-a-test-work_package")
      end

      it "shows a commit message with space between title and link" do
        gitlab_tab.git_actions_menu_button.click

        commit_message_input_text = page.find_field("Commit message").value
        expect(commit_message_input_text).to include("A test work_package http://")
      end

      it "allows the user to copy a commit message with newlines between title and link to the clipboard" do
        gitlab_tab.git_actions_menu_button.click
        gitlab_tab.git_actions_copy_commit_message_button.click

        expect(page).to have_text("Copied!")
        expect_clipboard_content("A test work_package\nhttp://")
      end
    end

    context "when there are no merge requests or issues" do
      let(:pipeline) { nil }
      let(:merge_request) { nil }
      let(:issue) { nil }

      it "shows the gitlab tab with an empty message" do
        work_package_page.visit!
        work_package_page.switch_to_tab(tab: "gitlab")
        tabs.expect_no_counter(gitlab_tab_element)

        expect(page).to have_content("There are no issues linked yet.")
        expect(page).to have_content("Link an existing issue by using the code OP##{work_package.id} " \
                                     "(or PP##{work_package.id} for private links) in the issue title/description " \
                                     "or create a new issue")

        expect(page).to have_content("There are no merge requests")
        expect(page).to have_content("Link an existing MR by using the code OP##{work_package.id}")
      end
    end

    context "when the user does not have the permissions to see the gitlab tab" do
      let(:role) do
        create(:project_role,
               permissions: %i(view_work_packages
                               add_work_package_notes))
      end

      it "does not show the gitlab tab" do
        work_package_page.visit!

        gitlab_tab.expect_tab_not_present
      end
    end

    context "when the gitlab integration is not enabled for the project" do
      let(:project) { create(:project, disable_modules: "gitlab") }

      it "does not show the gitlab tab" do
        work_package_page.visit!

        gitlab_tab.expect_tab_not_present
      end
    end
  end

  describe "work package full view" do
    let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }

    it_behaves_like "a gitlab tab"
  end

  describe "work package split view" do
    let(:work_package_page) { Pages::SplitWorkPackage.new(work_package) }

    it_behaves_like "a gitlab tab"
  end
end
