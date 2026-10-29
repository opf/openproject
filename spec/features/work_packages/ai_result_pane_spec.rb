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
               with_flag: { ai_text_transform_actions: true },
               with_settings: { ai_text_transform_actions_enabled: true } do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:work_package) { create(:work_package, project:, type:, description: "Login page dont work.") }
  shared_let(:fix_grammar) { create(:ai_text_transform_action, label: "Fix grammar") }
  shared_let(:user) { create(:admin) }

  let(:work_package_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }
  let(:description) { TextEditorField.new(work_package_page, "description") }
  let(:comment_form) { page.find_test_selector("op-work-package-journal-form-element") }

  before do
    gateway = AI::TextTransforms::FakeGateway.new(deltas: ["Login page ", "does **not** work."])
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
