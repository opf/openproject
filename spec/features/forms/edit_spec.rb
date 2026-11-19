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

RSpec.describe "Editing a form on its page", :js, with_ee: %i[edit_attribute_groups] do
  shared_let(:admin) { create(:admin) }

  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:task) { create(:type, name: "Task") }
  shared_let(:shared_form) { bug.default_variant.form_configuration }

  shared_let(:project) { create(:project, types: [bug, task]) }
  shared_let(:task_package) { create(:work_package, project:, type: task) }

  before_all do
    orphan = task.default_variant.form_configuration
    task.default_variant.update!(form_configuration: shared_form)
    orphan.reload.destroy!
  end

  let(:form) { Components::Admin::TypeConfigurationForm.new }

  current_user { admin }

  def members_of(type)
    type.default_variant.reload.attribute_groups.flat_map(&:members)
  end

  it "changes the form for every type that uses it" do
    visit edit_form_configuration_path(shared_form)

    form.rename_group("Details", "Specifics")
    form.remove_attribute("assignee")
    wait_for { members_of(task) }.not_to include("assignee")

    visit edit_type_form_configuration_path(type_id: task.id)

    form.expect_group("Specifics", "Specifics")
    within_test_selector("type-form-configuration-groups-container") do
      expect(page).to have_no_css(form.attribute_selector("assignee"))
    end

    wp_page = Pages::FullWorkPackage.new(task_package)
    wp_page.visit!
    wp_page.ensure_page_loaded

    wp_page.expect_group("Specifics")
    wp_page.expect_hidden_field(:assignee)
  end

  it "leaves the structure of the form to its page on a type's tab" do
    visit edit_type_form_configuration_path(type_id: task.id)

    expect(page).to have_test_selector("form-configuration-read-only")
    form.expect_group("Details", "Details")

    group_key = form.find_group("Details")["data-group-key"]
    expect(page).to have_no_test_selector("type-form-configuration-add-button")
    expect(page).to have_no_test_selector("type-form-configuration-group-actions-#{group_key}")
    expect(page).to have_no_test_selector("type-form-configuration-attribute-actions-assignee")
  end

  it "edits a form no type uses" do
    spare = create(:form_configuration, name: "Spare form")

    visit edit_form_configuration_path(spare)

    form.add_attribute_group("Extra")
    wait_for { FormConfiguration.find(spare.id).attribute_groups.map(&:translated_key) }.to include("Extra")

    visit edit_form_configuration_path(spare)

    form.expect_group("Extra", "Extra")
  end
end
