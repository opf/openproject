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

RSpec.describe "Custom fields reporting", :js do
  let(:type) { create(:type) }
  let(:project) { create(:project, types: [type]) }

  let(:user) { create(:admin) }

  let(:work_package) do
    create(:work_package,
           project:,
           type:,
           custom_values: initial_custom_values)
  end

  let!(:time_entry1) do
    create(:time_entry,
           user:,
           work_package:,
           project:,
           hours: 10)
  end

  let!(:time_entry2) do
    create(:time_entry,
           user:,
           work_package:,
           project:,
           hours: 2.50)
  end

  def custom_value_for(cf, str)
    cf.custom_options.find { |co| co.value == str }.try(:id)
  end

  current_user { user }

  context "with multi value cf" do
    let!(:custom_field) do
      create(:list_wp_custom_field,
             name: "List CF",
             multi_value: true,
             types: [type],
             projects: [project],
             possible_values: ["First option", "Second option"])
    end

    let(:initial_custom_values) { { custom_field.id => custom_value_for(custom_field, "First option") } }
    let(:cf_id) { "custom_field#{custom_field.id}" }

    # Have a second work package in the test that will have no values
    # as this caused problems with casting the nil value of the custom value to 0.
    let!(:work_package2) do
      create(:work_package,
             project:,
             type:)
    end

    before do
      visit "/cost_reports"
      sleep(0.1)
    end

    it "filters by the multi CF" do
      expect(page).to have_css("#add_filter_select option", text: "List CF")
      select "List CF", from: "add_filter_select"

      # Adds filter to page, filtering out the time entries on the work package
      expect(page).to have_css("label##{cf_id}")
      custom_field_selector = "##{cf_id}_arg_1_val"
      select = find(custom_field_selector)
      expect(select).to have_css("option", text: "First option")
      expect(select).to have_css("option", text: "Second option")
      select.find("option", text: "Second option").select_option

      click_link "Apply"

      # Expect empty result table
      within("#result-table") do
        expect(page).to have_no_css(".top.result", text: "12.50 hours")
      end
      expect(page).to have_css(".generic-table--no-results-title")

      # Update filter to value the work package has
      select = find(custom_field_selector)
      select.find("option", text: "First option").select_option
      find_by_id("query-icon-apply-button").click

      # Expect row of work package
      within("#result-table") do
        expect(page).to have_css(".top.result", text: "12.50 hours")
      end
    end

    it "groups by the multi CF (Regression #26050)" do
      expect(page).to have_css("#group-by--add-columns")
      expect(page).to have_css("#group-by--add-rows")

      select "List CF", from: "group-by--add-columns"
      select "Work package", from: "group-by--add-rows"

      click_link "Apply"

      # Expect row of work package
      within("#result-table") do
        expect(page).to have_css("a.work_package", text: "#{work_package.type} ##{work_package.id}")
        # There used to be additional and unwanted text after the option name being rendered.
        expect(page).to have_css("th.inner", text: /^First option$/)
        expect(page).to have_no_css("th.inner", text: "Second option")

        # Only first option should have content for the work package
        expect(page).to have_css("table.report tbody tr", count: 1)
        row_elements = page.all("table.report tr.odd th")

        expect(row_elements[0].text).to eq(project.name)
        expect(row_elements[1].text).to eq(work_package.to_s)

        row_elements = page.all("table.report tr.odd td")
        expect(row_elements[0].text).to eq("12.50 hours")
      end
    end

    context "with additional WP with invalid value" do
      let!(:custom_field_2) do
        create(:list_wp_custom_field,
               name: "Invalid List CF",
               multi_value: true,
               types: [type],
               projects: [project],
               possible_values: %w[A B])
      end

      let!(:work_package2) do
        create(:work_package,
               project:,
               custom_values: { custom_field_2.id => custom_value_for(custom_field_2, "A") })
      end

      let!(:time_entry1) do
        create(:time_entry,
               user:,
               work_package: work_package2,
               project:,
               hours: 10)
      end

      before do
        CustomValue.find_by(customized_id: work_package2.id).update_columns(value: "invalid")
        work_package2.reload

        visit "/cost_reports"
        sleep(0.1)
      end

      it "groups by the raw values when an invalid value exists" do
        expect(work_package2.send(custom_field_2.attribute_getter)).to eq(["invalid not found"])

        expect(page).to have_css("#group-by--add-columns")
        expect(page).to have_css("#group-by--add-rows")

        select "Invalid List CF", from: "group-by--add-columns"
        select "Work package", from: "group-by--add-rows"

        sleep(0.1)
        click_link "Apply"

        # Expect row of work package
        within("#result-table") do
          expect(page).to have_css("a.work_package", text: "#{work_package.type} ##{work_package.id}")
          expect(page).to have_css("th.inner", text: "1")
          expect(page).to have_no_css("th.inner", text: "invalid!")
        end
      end
    end
  end

  context "with text CF" do
    let(:custom_field) do
      create(:text_wp_custom_field,
             name: "Text CF",
             types: [type],
             projects: [project])
    end
    let(:initial_custom_values) { { custom_field.id => "foo" } }

    before do
      visit "/cost_reports"
      sleep(0.1)
    end

    it "groups by a text CF" do
      expect(page).to have_css("#group-by--add-columns")
      expect(page).to have_css("#group-by--add-rows")

      select "Text CF", from: "group-by--add-columns"
      select "Work package", from: "group-by--add-rows"

      click_link "Apply"

      # Expect row of work package
      within("#result-table") do
        expect(page).to have_css("a.work_package", text: "#{work_package.type} ##{work_package.id}")
        expect(page).to have_css("th.inner", text: "foo")
        expect(page).to have_no_css("th.inner", text: "None")

        # Only first option should have content for the work package
        expect(page).to have_css("table.report tbody tr", count: 1)
        row_elements = page.all("table.report tr.odd th")

        expect(row_elements[0].text).to eq(project.name)
        expect(row_elements[1].text).to eq(work_package.to_s)

        row_elements = page.all("table.report tr.odd td")
        expect(row_elements[0].text).to eq("12.50 hours")
      end
    end
  end
end
