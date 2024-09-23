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

RSpec.describe "Work package index sums", :js do
  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:status_new) { create(:status, name: "New") }
  shared_let(:status_in_progress) { create(:status, name: "In progress") }
  shared_let(:project) { create(:project, types: [type_bug, type_task]) }

  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_own_hourly_rate
                                                    view_work_packages
                                                    edit_work_packages
                                                    view_time_entries
                                                    view_cost_entries
                                                    view_cost_rates
                                                    log_costs] })
  end
  let!(:int_cf) do
    create(:integer_wp_custom_field) do |cf|
      project.work_package_custom_fields << cf
      type_bug.custom_fields << cf
      type_task.custom_fields << cf
    end
  end
  let!(:float_cf) do
    create(:float_wp_custom_field) do |cf|
      project.work_package_custom_fields << cf
      type_bug.custom_fields << cf
      type_task.custom_fields << cf
    end
  end
  let!(:work_package1) do
    create(:work_package,
           project:,
           type: type_bug,
           status: status_new,
           estimated_hours: 10,
           remaining_hours: 5) do |wp|
      wp.custom_field_values = { int_cf.id => 5, float_cf.id => 5.5 }
      wp.save!
    end
  end
  let!(:work_package2) do
    create(:work_package,
           project:,
           type: type_task,
           status: status_in_progress,
           estimated_hours: 15,
           remaining_hours: 7.5) do |wp|
      wp.custom_field_values = { int_cf.id => 7, float_cf.id => 7.7 }
      wp.save!
    end
  end
  # labor costs
  let!(:hourly_rate) do
    create(:default_hourly_rate,
           user:,
           rate: 10.00)
  end
  let!(:time_entry) do
    create(:time_entry,
           user:,
           work_package: work_package1,
           project:,
           hours: 1.50)
  end
  # unit costs
  let(:cost_type) do
    type = create(:cost_type, name: "Translations")
    create(:cost_rate,
           cost_type: type,
           rate: 3.00)
    type
  end
  let!(:cost_entry) do
    create(:cost_entry,
           work_package: work_package1,
           project:,
           units: 2.50,
           cost_type:,
           user:)
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { Components::WorkPackages::Columns.new }
  let(:modal) { Components::WorkPackages::TableConfigurationModal.new }
  let(:group_by) { Components::WorkPackages::GroupBy.new }
  let(:filters) { Components::WorkPackages::Filters.new }

  current_user { user }

  it "calculates sums correctly" do
    visit project_work_packages_path(project)
    wp_table.expect_work_package_listed work_package1, work_package2

    # Add work column
    columns.add "Work"
    # Add remaining work column
    columns.add "Remaining work"
    # Add int cf column
    columns.add int_cf.name
    # Add float cf column
    columns.add float_cf.name
    # Add labor costs column
    columns.add "Labor costs"
    # Add unit costs column
    columns.add "Unit costs"
    # Add overall costs column
    columns.add "Overall costs"

    # Trigger action from action menu dropdown
    modal.set_display_sums enable: true

    wp_table.expect_work_package_listed work_package1, work_package2

    # Expect the total sums row
    aggregate_failures do
      within(:row, "Total sum") do |row|
        expect(row).to have_css(".estimatedTime", text: "25h")
        expect(row).to have_css(".remainingTime", text: "12.5h")
        expect(row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: "12")
        expect(row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: "13.2")
        expect(row).to have_css(".laborCosts", text: "15.00 EUR")
        expect(row).to have_css(".materialCosts", text: "7.50 EUR") # Unit costs
        expect(row).to have_css(".overallCosts", text: "22.50 EUR")
      end
    end

    # Update the sum
    wp_table.edit_field(work_package1, :estimatedTime)
            .update "20"
    wp_table.edit_field(work_package1, :remainingTime)
            .update "12"

    aggregate_failures do
      within(:row, "Total sum") do |row|
        expect(row).to have_css(".estimatedTime", text: "35h")
        expect(row).to have_css(".remainingTime", text: "19.5h")
        expect(row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: "12")
        expect(row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: "13.2")
        expect(row).to have_css(".laborCosts", text: "15.00 EUR")
        expect(row).to have_css(".materialCosts", text: "7.50 EUR") # Unit costs
        expect(row).to have_css(".overallCosts", text: "22.50 EUR")
      end
    end

    # Enable groups
    group_by.enable_via_menu "Status"

    # Expect to have three sums rows now
    expect(page).to have_row("Sum", count: 2)
    expect(page).to have_row("Total sum", count: 1)

    first_sum_row, second_sum_row = *find_all(:row, "Sum")
    # First status row
    aggregate_failures do
      expect(first_sum_row).to have_css(".estimatedTime", text: "20h")
      expect(first_sum_row).to have_css(".remainingTime", text: "12h")
      expect(first_sum_row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: "5")
      expect(first_sum_row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: "5.5")
      expect(first_sum_row).to have_css(".laborCosts", text: "15.00 EUR")
      expect(first_sum_row).to have_css(".materialCosts", text: "7.50 EUR") # Unit costs
      expect(first_sum_row).to have_css(".overallCosts", text: "22.50 EUR")
    end

    # Second status row
    aggregate_failures do
      expect(second_sum_row).to have_css(".estimatedTime", text: "15h")
      expect(second_sum_row).to have_css(".remainingTime", text: "7.5h")
      expect(second_sum_row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: "7")
      expect(second_sum_row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: "7.7")
      expect(second_sum_row).to have_css(".laborCosts", text: "", exact_text: true)
      expect(second_sum_row).to have_css(".materialCosts", text: "", exact_text: true) # Unit costs
      expect(second_sum_row).to have_css(".overallCosts", text: "", exact_text: true)
    end

    # Total sums row is unchanged
    aggregate_failures do
      within(:row, "Total sum") do |row|
        expect(row).to have_css(".estimatedTime", text: "35h")
        expect(row).to have_css(".remainingTime", text: "19.5h")
        expect(row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: "12")
        expect(row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: "13.2")
        expect(row).to have_css(".laborCosts", text: "15.00 EUR")
        expect(row).to have_css(".materialCosts", text: "7.50 EUR") # Unit costs
        expect(row).to have_css(".overallCosts", text: "22.50 EUR")
      end
    end

    # Collapsing groups will also hide the sums row
    page.find(".expander.icon-minus2", match: :first).click
    sleep 1
    page.find(".expander.icon-minus2", match: :first).click

    # Expect to have only the final sums
    expect(page).not_to have_row("Sum")
    expect(page).to have_row("Total sum")
  end

  context "when filtering" do
    let!(:work_package3) do
      create(:work_package,
             project:,
             type: type_bug,
             status: status_in_progress,
             estimated_hours: 10,
             remaining_hours: 5) do |wp|
        wp.custom_field_values = { int_cf.id => 5, float_cf.id => 5.5 }
        wp.save!
      end
    end
    let!(:work_package4) do
      create(:work_package,
             project:,
             type: type_task,
             status: status_new,
             estimated_hours: 15,
             remaining_hours: 7.5) do |wp|
        wp.custom_field_values = { int_cf.id => 7, float_cf.id => 7.7 }
        wp.save!
      end
    end
    # labor costs
    let!(:time_entry2) do
      create(:time_entry,
             user:,
             work_package: work_package3,
             project:,
             hours: 2.50)
    end
    # unit costs
    let!(:cost_entry2) do
      create(:cost_entry,
             work_package: work_package3,
             project:,
             units: 3.50,
             cost_type:,
             user:)
    end

    it "calculates sums correctly" do
      query = create(:query,
                     project:,
                     user:,
                     display_sums: true,
                     column_names: [:id, :subject, :type, :status, :estimated_hours, :remaining_hours,
                                    :"#{int_cf.column_name}", :"#{float_cf.column_name}",
                                    :labor_costs, :material_costs, :overall_costs])
      wp_table.visit_query query
      wp_table.expect_work_package_listed work_package1, work_package2, work_package3, work_package4

      # Expect the total sums row without filtering
      aggregate_failures do
        within(:row, "Total sum") do |row|
          expect(row).to have_css(".estimatedTime", text: "50h")
          expect(row).to have_css(".remainingTime", text: "25h")
          expect(row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: "24")
          expect(row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: "26.4")
          expect(row).to have_css(".laborCosts", text: "40.00 EUR")
          expect(row).to have_css(".materialCosts", text: "18.00 EUR") # Unit costs
          expect(row).to have_css(".overallCosts", text: "58.00 EUR")
        end
      end

      # Filter
      filters.open
      filters.add_filter_by("Type", "is (OR)", type_task.name)

      # Expect 2 work packages shown
      expect(page).to have_row("WorkPackage", count: 2) # works because the subject name includes "WorkPackage"

      # Expect the total sums row to have changed
      aggregate_failures do
        within(:row, "Total sum") do |row|
          expect(row).to have_css(".estimatedTime", text: "30h")
          expect(row).to have_css(".remainingTime", text: "15h")
          expect(row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: "14")
          expect(row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: "15.4")
          expect(row).to have_css(".laborCosts", text: "", exact_text: true)
          expect(row).to have_css(".materialCosts", text: "", exact_text: true) # Unit costs
          expect(row).to have_css(".overallCosts", text: "", exact_text: true)
        end
      end

      # Filter by status open
      filters.remove_filter("type")
      filters.remove_filter("status")
      filters.add_filter_by("Status", "is (OR)", status_new.name)

      # Enable groups by type
      group_by.enable_via_menu "Type"

      # Expect to have three sums rows now
      expect(page).to have_row("Sum", count: 2)
      expect(page).to have_row("Total sum", count: 1)

      first_sum_row, second_sum_row = *find_all(:row, "Sum")
      # First status row
      aggregate_failures do
        expect(first_sum_row).to have_css(".estimatedTime", text: "10h")
        expect(first_sum_row).to have_css(".remainingTime", text: "5h")
        expect(first_sum_row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: "5")
        expect(first_sum_row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: "5.5")
        expect(first_sum_row).to have_css(".laborCosts", text: "15.00 EUR")
        expect(first_sum_row).to have_css(".materialCosts", text: "7.50 EUR") # Unit costs
        expect(first_sum_row).to have_css(".overallCosts", text: "22.50 EUR")
      end

      # Second status row
      aggregate_failures do
        expect(second_sum_row).to have_css(".estimatedTime", text: "15h")
        expect(second_sum_row).to have_css(".remainingTime", text: "7.5h")
        expect(second_sum_row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: "7")
        expect(second_sum_row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: "7.7")
        expect(second_sum_row).to have_css(".laborCosts", text: "", exact_text: true)
        expect(second_sum_row).to have_css(".materialCosts", text: "", exact_text: true) # Unit costs
        expect(second_sum_row).to have_css(".overallCosts", text: "", exact_text: true)
      end

      # Total sum
      aggregate_failures do
        within(:row, "Total sum") do |row|
          expect(row).to have_css(".estimatedTime", text: "25h")
          expect(row).to have_css(".remainingTime", text: "12.5h")
          expect(row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: "12")
          expect(row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: "13.2")
          expect(row).to have_css(".laborCosts", text: "15.00 EUR")
          expect(row).to have_css(".materialCosts", text: "7.50 EUR") # Unit costs
          expect(row).to have_css(".overallCosts", text: "22.50 EUR")
        end
      end
    end
  end
end
