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
require "support/edit_fields/edit_field"
require "support/edit_fields/text_editor_field"

RSpec.describe "Editor Assistant result pane",
               :js,
               with_flag: { ai_text_actions: true } do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:work_package) { create(:work_package, project:, type:, description: "Login page dont work.") }
  shared_let(:fix_grammar) { create(:ai_text_action, label: "Fix grammar") }
  shared_let(:user) { create(:admin) }

  let(:work_package_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }
  let(:description) { TextEditorField.new(work_package_page, "description") }
  let(:comment_form) { page.find_test_selector("op-work-package-journal-form-element") }

  let(:deltas) { ["Login page ", "does **not** work."] }

  before do
    gateway = AI::TextTransforms::FakeGateway.new(deltas:)
    allow(AI::TextTransforms::Gateway).to receive(:build).and_return(gateway)

    login_as(user)
    work_package_page.visit!
    work_package_page.ensure_page_loaded
  end

  def run_assistant(within:)
    within.find(".op-ai-actions .ck-splitbutton__action", text: "Fix grammar").click
    expect(page).to have_test_selector("ai-text-transform-result", text: "Generating…")
  end

  def finish_run
    AI::TextTransformJob.perform_now(AI::TextTransformRun.sole.id)
  end

  def replace
    page.within_test_selector("ai-text-transform-result") do
      expect(page).to have_css("strong", text: "not")
      click_button "Replace"
    end
    expect(page).not_to have_test_selector("ai-text-transform-result")
  end

  def in_ckeditor(container, script, *)
    page.execute_script(<<~JS, container.find(".ck-content").native, *)
      const editor = arguments[0].ckeditorInstance;
      const root = editor.model.document.getRoot();
      #{script}
    JS
  end

  def select_paragraph(container, index:)
    in_ckeditor(container, <<~JS, index)
      editor.model.change((writer) => writer.setSelection(root.getChild(arguments[1]), "in"));
    JS
  end

  def delete_paragraph(container, index:)
    in_ckeditor(container, <<~JS, index)
      editor.model.change((writer) => writer.remove(root.getChild(arguments[1])));
    JS
  end

  it "replaces the whole description with the generated text" do
    description.activate!
    run_assistant(within: description.field_container)
    expect(AI::TextTransformRun.sole.input).to eq("Login page dont work.")

    finish_run
    replace

    description.ckeditor.expect_value("Login page does not work.")
    description.save!
    work_package_page.expect_and_dismiss_toaster(message: "Successful update.")
    expect(work_package.reload.description).to eq("Login page does **not** work.")
  end

  it "replaces only the selected paragraph" do
    description.activate!
    description.ckeditor.set_markdown("Keep this intro.\n\nLogin page dont work.")
    select_paragraph(description.field_container, index: 1)
    run_assistant(within: description.field_container)
    expect(AI::TextTransformRun.sole.input).to eq("Login page dont work.")

    finish_run
    replace

    description.ckeditor.expect_value("Keep this intro.\nLogin page does not work.")
    description.save!
    work_package_page.expect_and_dismiss_toaster(message: "Successful update.")
    expect(work_package.reload.description).to eq("Keep this intro.\n\nLogin page does **not** work.")
  end

  it "keeps the editor unchanged when the selected text was deleted meanwhile" do
    description.activate!
    description.ckeditor.set_markdown("Keep this intro.\n\nLogin page dont work.")
    select_paragraph(description.field_container, index: 1)
    run_assistant(within: description.field_container)

    delete_paragraph(description.field_container, index: 1)
    finish_run
    page.within_test_selector("ai-text-transform-result") do
      expect(page).to have_css("strong", text: "not")
      click_button "Replace"
      expect(page).to have_text("The selected text is no longer there")
    end

    description.ckeditor.expect_value("Keep this intro.")
  end

  context "with formatted text" do
    shared_let(:work_package) { create(:work_package, project:, type:, description: "Login page **dont** work.") }

    it "undoes the replacement in one step and restores the formatting" do
      description.activate!
      run_assistant(within: description.field_container)

      finish_run
      replace
      description.ckeditor.expect_value("Login page does not work.")

      description.ckeditor.editor_element.click
      description.ckeditor.editor_element.send_keys([:control, "z"])

      description.ckeditor.expect_value("Login page dont work.")
      expect(description.field_container).to have_css(".ck-content strong", text: "dont")
      expect(description.field_container).to have_no_css(".ck-content strong", text: "not")
    end
  end

  context "with a mention the description did not have" do
    shared_let(:group) { create(:group, lastname: "Devs") }
    let(:deltas) do
      ["Login page does not work. ",
       %(<mention class="mention" data-id="#{group.id}" data-type="group" data-text="@Devs">@Devs</mention>)]
    end

    it "inserts it as plain text and tells the user why" do
      description.activate!
      run_assistant(within: description.field_container)

      finish_run
      page.within_test_selector("ai-text-transform-result") do
        expect(page).to have_test_selector("ai-text-transform-pane-mentions-converted",
                                           text: "were turned into plain text so no one is notified")
        click_button "Replace"
      end
      expect(page).not_to have_test_selector("ai-text-transform-result")

      description.ckeditor.expect_value("Login page does not work. @Devs")
      expect(description.field_container).to have_no_css(".ck-content .mention")
    end
  end

  it "replaces the text of a comment" do
    work_package_page.wait_for_activity_tab
    activity_tab.type_comment("Login page dont work.")
    run_assistant(within: comment_form)

    finish_run
    replace

    activity_tab.ckeditor.expect_value("Login page does not work.")
  end

  it "cancels the run with the pane" do
    description.activate!
    run_assistant(within: description.field_container)

    page.within_test_selector("ai-text-transform-result") { click_button "Cancel" }

    expect(page).not_to have_test_selector("ai-text-transform-result")
    expect(AI::TextTransformRun.sole.cancel_requested).to be(true)
    description.ckeditor.expect_value("Login page dont work.")
  end
end
