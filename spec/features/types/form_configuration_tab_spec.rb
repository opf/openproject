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

RSpec.describe "Editing the form on a type's tab", :js do
  shared_let(:admin) { create(:admin) }

  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:task) { create(:type, name: "Task") }
  shared_let(:shared_form) { bug.default_variant.form_configuration }

  shared_let(:project) { create(:project, types: [bug, task]) }
  shared_let(:bug_package) { create(:work_package, project:, type: bug) }
  shared_let(:task_package) { create(:work_package, project:, type: task) }

  before_all do
    shared_form.update!(name: "Shared form")
    bug.default_variant.update!(attribute_groups: [["People", %w[assignee responsible]]])

    orphan = task.default_variant.form_configuration
    task.default_variant.update!(form_configuration: shared_form)
    orphan.reload.destroy!
  end

  let(:form) { Components::Admin::TypeConfigurationForm.new }
  let(:variant) { task.default_variant }

  current_user { admin }

  def toggle_for(key)
    page.find("[data-test-selector='toggle-form-config-exclusion-#{key}'] > button")
  end

  def expect_toggle(key, pressed:)
    expect(page)
      .to have_css("[data-test-selector='toggle-form-config-exclusion-#{key}'] > button[aria-pressed='#{pressed}']")
  end

  def expect_field_on(work_package, attribute, shown:)
    wp_page = Pages::FullWorkPackage.new(work_package)
    wp_page.visit!
    wp_page.ensure_page_loaded

    if shown
      expect(page).to have_css(".inline-edit--display-field.#{attribute}")
    else
      wp_page.expect_hidden_field(attribute)
    end
  end

  def switch_to(name)
    page.find_test_selector("form_configuration-selector").click
    within_test_selector("form_configuration-panel") { click_link name }

    within_test_selector("form_configuration-selector") { expect(page).to have_text(name) }
  end

  it "hides a field for this type only, leaving the shared form alone" do
    visit edit_type_form_configuration_path(type_id: task.id)

    expect_toggle("assignee", pressed: true)
    toggle_for("assignee").click
    expect_toggle("assignee", pressed: false)
    expect(variant.reload.form_configuration_excluded_elements).to eq(%w[assignee])

    expect_field_on(task_package, :assignee, shown: false)
    expect_field_on(bug_package, :assignee, shown: true)

    visit edit_form_configuration_path(shared_form)

    form.expect_group("People", "People", { key: :assignee })
  end

  it "drops the hidden fields the form it switches to does not have" do
    slim_form = create(:form_configuration, name: "Slim form")
    slim_form.update!(attribute_groups: [["Summary", %w[responsible]]])
    variant.update!(form_configuration_excluded_elements: %w[assignee responsible])

    visit edit_type_form_configuration_path(type_id: task.id)

    expect_toggle("assignee", pressed: false)
    switch_to("Slim form")

    form.expect_group("Summary", "Summary")
    expect_toggle("responsible", pressed: false)
    expect(variant.reload.form_configuration_excluded_elements).to eq(%w[responsible])

    switch_to("Shared form")

    expect_toggle("assignee", pressed: true)
    expect_toggle("responsible", pressed: false)
  end
end
