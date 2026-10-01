# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

RSpec.describe "Projects lists ordering", :js, with_settings: { login_required?: false } do
  shared_let(:admin) { create(:admin) }

  shared_let(:custom_field) { create(:text_project_custom_field) }
  shared_let(:invisible_custom_field) { create(:project_custom_field, admin_only: true) }

  shared_let(:project) { create(:project, name: "Plain project", identifier: "plain-project") }
  shared_let(:public_project) do
    create(:project, name: "Public Pr", identifier: "public-pr", public: true) do |project|
      project.custom_field_values = { invisible_custom_field.id => "Secret CF" }
    end
  end
  shared_let(:development_project) { create(:project, name: "Development project", identifier: "development-project") }

  let(:projects_page) { Pages::Projects::Index.new }

  shared_let(:integer_custom_field) { create(:integer_project_custom_field) }
  # order is important here as the implementation uses lft
  # first but then reorders in ruby
  shared_let(:child_project_z) { create(:project, parent: project, name: "Z Child") }

  # intentionally written lowercase to test for case-insensitive sorting
  shared_let(:child_project_m) { create(:project, parent: project, name: "m Child") }

  shared_let(:child_project_a) { create(:project, parent: project, name: "A Child") }

  before do
    login_as(admin)
    visit projects_path

    project.custom_field_values = { integer_custom_field.id => 1 }
    project.save!
    development_project.custom_field_values = { integer_custom_field.id => 2 }
    development_project.save!
    public_project.custom_field_values = { integer_custom_field.id => 3 }
    public_project.save!
    child_project_z.custom_field_values = { integer_custom_field.id => 4 }
    child_project_z.save!
    child_project_m.custom_field_values = { integer_custom_field.id => 4 }
    child_project_m.save!
    child_project_a.custom_field_values = { integer_custom_field.id => 4 }
    child_project_a.save!
  end

  context "via the configure view dialog" do
    before do
      Setting.enabled_projects_columns += [integer_custom_field.column_name]
    end

    it "allows to sort via multiple columns" do
      projects_page.open_configure_view
      projects_page.switch_configure_view_tab(I18n.t("label_sort"))

      # Initially we have the projects ordered by hierarchy
      # When we sort by hierarchy, there is a special behavior that no other sorting is possible
      # and the sort order is always ascending
      projects_page.within_sort_row(0) do
        projects_page.expect_sort_order(column_identifier: "lft", direction: "asc", direction_enabled: false)
      end
      projects_page.expect_number_of_sort_fields(1)

      # Switch sorting order to Name descending
      # We now get a second sort field to add another sort order, but it has nothing selected
      # in the second field, name is not available as an option
      projects_page.within_sort_row(0) do
        projects_page.change_sort_order(column_identifier: :name, direction: :desc)
      end
      projects_page.expect_number_of_sort_fields(2)

      projects_page.within_sort_row(1) do
        projects_page.expect_sort_order(column_identifier: "", direction: "")
        projects_page.expect_sort_option_is_disabled(column_identifier: :name)
      end

      # Let's add another sorting, this time by a custom field
      # This will add a third sorting field
      projects_page.within_sort_row(1) do
        projects_page.change_sort_order(column_identifier: integer_custom_field.column_name, direction: :asc)
      end

      projects_page.expect_number_of_sort_fields(3)
      projects_page.within_sort_row(2) do
        projects_page.expect_sort_order(column_identifier: "", direction: "")
        projects_page.expect_sort_option_is_disabled(column_identifier: :name)
        projects_page.expect_sort_option_is_disabled(column_identifier: integer_custom_field.column_name)
      end

      # And now let's select a third option
      # it will not add a 4th sorting field
      projects_page.within_sort_row(2) do
        projects_page.change_sort_order(column_identifier: :public, direction: :asc)
      end
      projects_page.expect_number_of_sort_fields(3)

      # We unset the first sorting, this will move the 2nd sorting (custom field) to the first position and
      # the 3rd sorting (public) to the second position and will add an empty option to the third position
      projects_page.within_sort_row(0) do
        projects_page.remove_sort_order
      end

      projects_page.expect_number_of_sort_fields(3)

      projects_page.within_sort_row(0) do
        projects_page.expect_sort_order(column_identifier: integer_custom_field.column_name, direction: :asc)
      end
      projects_page.within_sort_row(1) { projects_page.expect_sort_order(column_identifier: :public, direction: :asc) }
      projects_page.within_sort_row(2) { projects_page.expect_sort_order(column_identifier: "", direction: "") }

      # To roll back, we now select hierarchy as the third option, this will remove all other options
      projects_page.within_sort_row(2) do
        projects_page.change_sort_order(column_identifier: :lft, direction: :asc)
      end

      projects_page.within_sort_row(0) do
        projects_page.expect_sort_order(column_identifier: "lft", direction: "asc", direction_enabled: false)
      end
      projects_page.expect_number_of_sort_fields(1)
    end

    it "resets the pagination when sorting (bug #55392)" do
      # We need pagination, so reduce the page size to enable it
      allow(Setting).to receive(:per_page_options_array).and_return([1, 5])
      projects_page.set_page_size(1)
      wait_for_reload
      projects_page.expect_page_size(1)
      projects_page.go_to_page(2) # Go to another page that is not the first one
      wait_for_reload
      projects_page.expect_current_page_number(2)

      # Open config dialog and make changes to the sorting
      projects_page.open_configure_view
      projects_page.switch_configure_view_tab(I18n.t("label_sort"))
      projects_page.within_sort_row(0) do
        projects_page.change_sort_order(column_identifier: :name, direction: :desc)
      end

      # Save and close the dialog
      projects_page.submit_config_view_dialog
      wait_for_reload

      # Changing the sorting resets the pagination to the first page
      projects_page.expect_current_page_number(1)

      # Go to another page again
      projects_page.go_to_page(2)
      wait_for_reload
      projects_page.expect_current_page_number(2)

      # Open dialog, do not change anything and save
      projects_page.open_configure_view
      projects_page.switch_configure_view_tab(I18n.t("label_sort"))
      projects_page.submit_config_view_dialog
      wait_for_reload

      # An unchanged sorting will keep the current position in the pagination
      projects_page.expect_current_page_number(2)
    end

    it "does not allow to sort via long text custom fields" do
      long_text_custom_field = create(:text_project_custom_field)
      Setting.enabled_projects_columns += [long_text_custom_field.column_name]

      projects_page.open_configure_view
      projects_page.switch_configure_view_tab(I18n.t("label_sort"))

      projects_page.within_sort_row(0) do
        projects_page.expect_sort_option_not_available(column_identifier: long_text_custom_field.column_name)
      end
    end
  end

  it "allows to alter the order in which projects are displayed via the column headers" do
    Setting.enabled_projects_columns += [integer_custom_field.column_name]

    # initially, ordered by name asc on each hierarchical level
    projects_page
      .expect_projects_in_order(development_project,
                                project,
                                child_project_a,
                                child_project_m,
                                child_project_z,
                                public_project)

    projects_page.click_table_header_to_open_action_menu("Name")
    projects_page.sort_via_action_menu("Name", direction: :asc)
    wait_for_reload

    # Projects ordered by name asc
    projects_page
      .expect_projects_in_order(child_project_a,
                                development_project,
                                child_project_m,
                                project,
                                public_project,
                                child_project_z)

    projects_page.click_table_header_to_open_action_menu("Name")
    projects_page.sort_via_action_menu("Name", direction: :desc)
    wait_for_reload

    # Projects ordered by name desc
    projects_page
      .expect_projects_in_order(child_project_z,
                                public_project,
                                project,
                                child_project_m,
                                development_project,
                                child_project_a)

    projects_page.click_table_header_to_open_action_menu(integer_custom_field.column_name)
    projects_page.sort_via_action_menu(integer_custom_field.column_name, direction: :asc)
    wait_for_reload

    # Projects ordered by cf asc first then project name desc
    projects_page
      .expect_projects_in_order(project,
                                development_project,
                                public_project,
                                child_project_z,
                                child_project_m,
                                child_project_a)

    click_link_or_button('Sort by "Project hierarchy"')
    wait_for_reload

    # again ordered by name asc on each hierarchical level
    projects_page
      .expect_projects_in_order(development_project,
                                project,
                                child_project_a,
                                child_project_m,
                                child_project_z,
                                public_project)
  end

  it "sorts projects by latest_activity_at" do
    projects_page.click_table_header_to_open_action_menu("latest_activity_at")
    projects_page.sort_via_action_menu("latest_activity_at", direction: :asc)
    wait_for_reload

    projects_page.expect_project_at_place(project, 1)
  end

  context "when sorting calculated value custom fields", with_ee: %i[calculated_values] do
    let(:projects_with_calculated_value) do
      [project, development_project, public_project, child_project_m, child_project_a]
    end

    let!(:calculated_value) do
      create(:calculated_value_project_custom_field,
             name: "Calculated value",
             formula: "1 + {{cf_#{integer_custom_field.id}}}",
             projects: projects_with_calculated_value)
    end

    before do
      projects_with_calculated_value.each do |proj|
        proj.calculate_custom_fields([calculated_value])
        proj.save!
      end

      Setting.enabled_projects_columns += [calculated_value.column_name]
      visit projects_path
    end

    it "sorts by calculated value custom fields" do
      projects_page.click_table_header_to_open_action_menu(calculated_value.column_name)
      projects_page.sort_via_action_menu(calculated_value.column_name, direction: :asc)
      wait_for_reload

      projects_page
        .expect_projects_in_order(child_project_z,
                                  project,
                                  development_project,
                                  public_project,
                                  child_project_a,
                                  child_project_m)
    end
  end

  context "when sorting by project phase" do
    let(:stage_def) { create(:project_phase_definition) }
    let(:stage) do
      create(:project_phase,
             project:,
             definition: stage_def,
             start_date: Date.new(2025, 1, 1),
             finish_date: Date.new(2025, 1, 13))
    end
    let!(:public_stage) do
      create(:project_phase,
             project: public_project,
             definition: stage_def,
             start_date: Date.new(2025, 2, 12),
             finish_date: Date.new(2025, 2, 20))
    end
    let!(:child_stage) do
      create(:project_phase,
             project: child_project_m,
             definition: stage_def,
             start_date: public_stage.start_date,
             finish_date: public_stage.finish_date + 1.day)
    end
    let!(:last_stage) do
      create(:project_phase,
             project: development_project,
             definition: stage_def,
             start_date: public_stage.start_date,
             finish_date: public_stage.finish_date + 2.days)
    end

    let(:gate_def) { create(:project_phase_definition, :with_start_gate) }
    let(:gate) do
      create(:project_phase,
             project:,
             definition: gate_def,
             start_date: Date.new(2025, 1, 1))
    end
    let!(:public_gate) do
      create(:project_phase,
             project: public_project,
             definition: gate_def,
             start_date: Date.new(2025, 2, 12))
    end
    let!(:child_gate) do
      create(:project_phase,
             project: child_project_m,
             definition: gate_def,
             start_date: public_gate.start_date + 1.day)
    end
    let!(:last_gate) do
      create(:project_phase,
             project: development_project,
             definition: gate_def,
             start_date: public_gate.start_date + 2.days)
    end

    shared_let(:project_phase_permissions) { %i(view_project view_project_phases) }
    shared_let(:basic_permissions) { %i(view_project) }

    shared_let(:user) do
      create(:user, member_with_permissions: { project => project_phase_permissions,
                                               development_project => project_phase_permissions,
                                               child_project_z => basic_permissions,
                                               child_project_m => basic_permissions,
                                               child_project_a => basic_permissions,
                                               public_project => project_phase_permissions })
    end

    before do
      Setting.enabled_projects_columns += %W[project_phase_#{stage.definition.id} project_phase_#{gate.definition.id}]
      visit projects_path
    end

    context "when sorting by project phase definition" do
      it "sorts projects by project phase asc" do
        projects_page.click_table_header_to_open_action_menu("project_phase_#{stage.definition.id}")
        projects_page.sort_via_action_menu("project_phase_#{stage.definition.id}", direction: :asc)
        wait_for_reload

        projects_page.expect_project_at_place(project, 1)
        # For the next three projects, the start date is the same, but the end date differs.
        # Ensure the end date is used as a secondary sorting criterion:
        projects_page.expect_project_at_place(public_project, 2)
        projects_page.expect_project_at_place(child_project_m, 3)
        projects_page.expect_project_at_place(development_project, 4)
      end

      it "sorts projects by project phase desc" do
        projects_page.click_table_header_to_open_action_menu("project_phase_#{stage.definition.id}")
        projects_page.sort_via_action_menu("project_phase_#{stage.definition.id}", direction: :desc)
        wait_for_reload

        projects_page.expect_project_at_place(development_project, 3)
        projects_page.expect_project_at_place(child_project_m, 4)
        projects_page.expect_project_at_place(public_project, 5)
        projects_page.expect_project_at_place(project, 6)
      end
    end

    context "when sorting by project phase gate definition" do
      it "sorts projects by project phase gate asc" do
        projects_page.click_table_header_to_open_action_menu("project_phase_#{gate.definition.id}")
        projects_page.sort_via_action_menu("project_phase_#{gate.definition.id}", direction: :asc)
        wait_for_reload

        projects_page.expect_project_at_place(project, 1)
        projects_page.expect_project_at_place(public_project, 2)
        projects_page.expect_project_at_place(child_project_m, 3)
        projects_page.expect_project_at_place(development_project, 4)
      end

      it "sorts projects by project phase gate desc" do
        projects_page.click_table_header_to_open_action_menu("project_phase_#{gate.definition.id}")
        projects_page.sort_via_action_menu("project_phase_#{gate.definition.id}", direction: :desc)
        wait_for_reload

        projects_page.expect_project_at_place(development_project, 3)
        projects_page.expect_project_at_place(child_project_m, 4)
        projects_page.expect_project_at_place(public_project, 5)
        projects_page.expect_project_at_place(project, 6)
      end
    end

    context "when sorting by both stage and gate at once" do
      it "sorts correctly" do
        projects_page.click_table_header_to_open_action_menu("project_phase_#{gate.definition.id}")
        projects_page.sort_via_action_menu("project_phase_#{gate.definition.id}", direction: :asc)
        wait_for_reload

        projects_page.click_table_header_to_open_action_menu("project_phase_#{stage.definition.id}")
        projects_page.sort_via_action_menu("project_phase_#{stage.definition.id}", direction: :desc)
        wait_for_reload

        projects_page.expect_project_at_place(development_project, 3)
        projects_page.expect_project_at_place(child_project_m, 4)
        projects_page.expect_project_at_place(public_project, 5)
        projects_page.expect_project_at_place(project, 6)
      end
    end

    context "without permission to view phases" do
      before do
        login_as(user)
        visit projects_path
      end

      it "does not consider the project phase dates of projects without permission" do
        projects_page.click_table_header_to_open_action_menu("project_phase_#{gate.definition.id}")
        projects_page.sort_via_action_menu("project_phase_#{gate.definition.id}", direction: :desc)
        wait_for_reload

        projects_page
          .expect_projects_in_order(child_project_a,
                                    # child project M has project phases, but user has no permission
                                    # to see them. That is why they are ignored for sorting.
                                    child_project_m,
                                    child_project_z,
                                    # Regular project phase sorting for the remaining projects:
                                    development_project,
                                    public_project,
                                    project)
      end
    end
  end
end
