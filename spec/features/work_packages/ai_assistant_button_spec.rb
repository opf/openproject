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

RSpec.describe "Editor Assistant button",
               :js,
               with_flag: { ai_text_actions: true } do
  shared_let(:type) { create(:type) }
  shared_let(:other_type) { create(:type) }
  shared_let(:project) { create(:project, types: [type, other_type]) }
  shared_let(:work_package) { create(:work_package, project:, type:, description: "Some text") }
  shared_let(:everywhere_action) { create(:ai_text_action, label: "Fix grammar", position: 1) }
  shared_let(:type_scoped_action) do
    create(:ai_text_action,
           label: "Sort into template",
           position: 2,
           usage_scope: "specific_work_package_types",
           types: [type])
  end
  shared_let(:other_type_scoped_action) do
    create(:ai_text_action,
           label: "Describe the bug",
           position: 0,
           usage_scope: "specific_work_package_types",
           types: [other_type])
  end
  shared_let(:user) { create(:admin) }

  before do
    allow(AI::TextTransforms::Gateway).to receive(:build).and_return(AI::TextTransforms::FakeGateway.new)

    login_as(user)
  end

  def expect_assistant_menu(within:, labels:)
    assistant = within.find(".op-ai-actions")
    expect(assistant).to have_css(".ck-splitbutton__action", text: labels.first, visible: :all)

    assistant.find(".ck-splitbutton__arrow").click
    expect(assistant).to have_css(".ck-list__item", count: labels.size)
    expect(assistant.all(".ck-list__item").map(&:text)).to eq(labels)
  end

  context "on an existing work package" do
    let(:work_package_page) { Pages::FullWorkPackage.new(work_package, project) }
    let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

    before do
      work_package_page.visit!
      work_package_page.ensure_page_loaded
    end

    it "offers the type-scoped actions in the description and the actions scoped everywhere in comments" do
      description = TextEditorField.new(work_package_page, "description")
      description.activate!

      expect_assistant_menu(within: description.field_container,
                            labels: ["Fix grammar", "Sort into template"])

      activity_tab.open_new_comment_editor
      expect_assistant_menu(within: page.find_test_selector("op-work-package-journal-form-element"),
                            labels: ["Fix grammar"])
    end
  end

  context "on a work package create form" do
    shared_let(:status) { create(:status, is_default: true) }
    shared_let(:priority) { create(:priority, is_default: true) }

    let(:create_page) { Pages::FullWorkPackageCreate.new }
    let(:description) { TextEditorField.new(create_page, "description") }
    let(:project_field) { create_page.edit_field(:project) }
    let(:type_field) { create_page.edit_field(:type) }

    def expect_description_editor
      expect(page).to have_css(".inline-edit--container.description .ck-content", wait: 20)
    end

    def expect_description_assistant_menu(labels:)
      expect(page).to have_css(".inline-edit--container.description .op-ai-actions", wait: 20)
      expect_assistant_menu(within: page.find(".inline-edit--container.description"), labels:)
    end

    it "offers the actions once a project is chosen on the global form and runs them for it" do
      visit "/work_packages/new?type=#{type.id}"
      expect_description_editor
      wait_for_network_idle
      expect(page).to have_no_css(".op-ai-actions")

      project_field.openSelectField
      project_field.set_value project.name
      description.set_value "Login page dont work."

      expect_description_assistant_menu(labels: ["Fix grammar", "Sort into template"])

      page.find(".op-ai-actions .ck-list__item", text: "Sort into template").click
      expect(page).to have_test_selector("ai-text-transform-result", text: "Generating…", wait: 20)
      expect(AI::TextTransformRun.sole.action).to eq(type_scoped_action)
    end

    it "follows the type chosen on the project form" do
      visit new_project_work_packages_path(project, type: type.id)
      expect_description_editor
      expect_description_assistant_menu(labels: ["Fix grammar", "Sort into template"])

      type_field.activate!
      type_field.set_value other_type.name
      wait_for_network_idle

      expect_description_assistant_menu(labels: ["Describe the bug", "Fix grammar"])
    end
  end
end
