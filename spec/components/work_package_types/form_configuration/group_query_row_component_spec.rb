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

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::GroupQueryRowComponent, type: :component do
  include_context "with variant scope"

  let(:group) do
    { key: "query-1", name: "Related", type: :query,
      query_summary: [{ label: "Relation type", values: ["Children"] }] }
  end

  it "renders the edit-query action when EE and editable" do
    render_inline(described_class.new(group:, ee_available: true))

    expect(page).to have_button(accessible_name: "Edit query")
  end

  it "carries the editor query on its stream target" do
    render_inline(described_class.new(group: group.merge(query: '{"filters":[]}'), ee_available: true))

    expect(page).to have_element(:div, id: "work-package-types-form-configuration-group-query-row-component-query-1") do |row|
      expect(row["data-group-query"]).to eq('{"filters":[]}')
    end
  end

  it "omits the editor query for a group whose query was deleted" do
    render_inline(described_class.new(group:, ee_available: true))

    expect(page).to have_element(:div, id: "work-package-types-form-configuration-group-query-row-component-query-1") do |row|
      expect(row["data-group-query"]).to be_nil
    end
  end

  it "omits the edit-query action when readonly", :aggregate_failures do
    render_inline(described_class.new(group:, ee_available: true, readonly: true))

    expect(page).to have_no_button(accessible_name: "Edit query")
    expect(page).to have_text("Related work packages table")
  end

  [true, false].each do |ee_available|
    [true, false].each do |readonly|
      it "preserves the label and summary with EE #{ee_available} and readonly #{readonly}" do
        render_inline(described_class.new(group:, ee_available:, readonly:))
        expect(page).to have_text("Related work packages table")
        expect(page).to have_element(:dt, text: "Relation type")
        expect(page).to have_element(:dd, text: "Children")
        if ee_available && !readonly
          expect(page).to have_button("Related work packages table")
        end
      end
    end
  end

  describe "the exclusion toggle" do
    let(:type) { create(:type) }
    let(:variant) { type.default_variant }
    let(:exclusions) do
      WorkPackageTypes::ExclusionState.new(variant:, excluded: [])
    end

    it "is keyed on the query and labelled with the section name", :aggregate_failures do
      render_inline(described_class.new(group: group.merge(element_key: "query_7"),
                                        ee_available: false, readonly: true, exclusions:))

      toggle = page.find("[data-test-selector='toggle-form-config-exclusion-query_7']")
      expect(toggle.find("button")["aria-label"]).to eq("Inherit section Related")
    end

    it "is omitted for a group whose query was deleted" do
      render_inline(described_class.new(group: group.merge(element_key: nil),
                                        ee_available: true, readonly: true, exclusions:))

      expect(page).to have_no_css("toggle-switch")
    end
  end
end
