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

  let(:group) { { key: "query-1", name: "Related", type: :query } }

  it "renders the edit-query action when EE and editable" do
    render_inline(described_class.new(group:, ee_available: true))

    expect(page).to have_test_selector("type-form-configuration-query-actions-query-1")
  end

  it "omits the actions menu when readonly", :aggregate_failures do
    render_inline(described_class.new(group:, ee_available: true, readonly: true))

    expect(page).to have_no_test_selector("type-form-configuration-query-actions-query-1")
    expect(page).to have_text("Related work packages table")
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
