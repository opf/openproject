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
               with_flag: { ai_text_transform_actions: true },
               with_settings: { ai_text_transform_actions_enabled: true } do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:work_package) { create(:work_package, project:, type:, description: "Some text") }
  shared_let(:everywhere_action) { create(:ai_text_transform_action, label: "Fix grammar", position: 1) }
  shared_let(:type_scoped_action) do
    create(:ai_text_transform_action,
           label: "Sort into template",
           position: 2,
           usage_scope: "specific_work_package_types",
           types: [type])
  end
  shared_let(:user) { create(:admin) }

  let(:work_package_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  before do
    allow(AI::TextTransforms::Gateway).to receive(:build).and_return(AI::TextTransforms::FakeGateway.new)

    login_as(user)
    work_package_page.visit!
    work_package_page.ensure_page_loaded
  end

  def expect_assistant_menu(within:, labels:)
    assistant = within.find(".op-ai-actions")
    expect(assistant).to have_css(".ck-splitbutton__action", text: labels.first)

    assistant.find(".ck-splitbutton__arrow").click
    expect(assistant).to have_css(".ck-list__item", count: labels.size)
    expect(assistant.all(".ck-list__item").map(&:text)).to eq(labels)
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
