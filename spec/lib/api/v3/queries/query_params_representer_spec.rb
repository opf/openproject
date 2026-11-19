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

RSpec.describe API::V3::Queries::QueryParamsRepresenter do
  subject(:params) { described_class.new(query).to_h }

  let(:query) do
    instance_double(
      Query,
      display_sums?: true,
      filters: [],
      group_by: "project",
      group_by?: true,
      has_default_columns?: true,
      highlighting_mode: :none,
      historic?: false,
      include_subprojects: true,
      ordered?: false,
      read_attribute: "none",
      show_hierarchies: true
    )
  end

  it "serializes the query display options used by exports" do
    expect(params).to include(
      includeSubprojects: true,
      showHierarchies: true,
      showSums: true,
      groupBy: "project"
    )
  end

  it "preserves highlighting when the query is serialized for editing" do
    expect(params).to include(highlightingMode: "none")
  end

  it "omits timestamps for a query at the current time" do
    expect(params).not_to have_key(:timestamps)
  end

  context "with a baseline" do
    it "keeps relative timestamps so the editor reopens on the saved option" do
      query = Query.new(timestamps: %w[P-1D PT0S])

      expect(described_class.new(query).to_h).to include(timestamps: "P-1D,PT0S")
    end
  end

  context "with inline highlighting of selected attributes" do
    let(:query) { Query.new(highlighting_mode: :inline, highlighted_attributes: %i[priority]) }

    it "keeps the selected attributes as column links" do
      expect(described_class.new(query).to_h)
        .to include(highlightedAttributes: ["/api/v3/queries/columns/priority"])
    end

    it "keys them as an array for the editor" do
      expect(JSON.parse(described_class.new(query).to_json))
        .to include("highlightedAttributes[]" => ["/api/v3/queries/columns/priority"])
    end
  end

  context "with inline highlighting inherited from the instance default" do
    it "omits highlighted attributes" do
      expect(described_class.new(Query.new(highlighting_mode: :inline)).to_h).not_to have_key(:highlightedAttributes)
    end
  end

  context "with stored highlighted attributes and the inline mode inherited from the instance default",
          with_settings: { work_package_list_default_highlighting_mode: "inline" } do
    let(:query) { Query.new(highlighted_attributes: %i[priority]) }

    it "keeps the stored attributes" do
      expect(described_class.new(query).to_h).to include(highlightedAttributes: ["/api/v3/queries/columns/priority"])
    end

    it "still omits the inherited mode" do
      expect(described_class.new(query).to_h).not_to have_key(:highlightingMode)
    end
  end

  context "with stored highlighted attributes under a stored non-inline mode" do
    let(:query) { Query.new(highlighting_mode: :status, highlighted_attributes: %i[priority]) }

    it "omits them" do
      expect(described_class.new(query).to_h).not_to have_key(:highlightedAttributes)
    end
  end

  context "with a non-inline instance default", with_settings: { work_package_list_default_highlighting_mode: "status" } do
    it "omits a highlighting mode inherited from the setting" do
      expect(described_class.new(Query.new).to_h).not_to have_key(:highlightingMode)
    end

    it "keeps an explicitly stored mode" do
      expect(described_class.new(Query.new(highlighting_mode: :inline)).to_h).to include(highlightingMode: "inline")
    end
  end
end
