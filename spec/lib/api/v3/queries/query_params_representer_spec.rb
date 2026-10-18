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

  context "with a non-inline instance default", with_settings: { work_package_list_default_highlighting_mode: "status" } do
    it "omits a highlighting mode inherited from the setting" do
      expect(described_class.new(Query.new).to_h).not_to have_key(:highlightingMode)
    end

    it "keeps an explicitly stored mode" do
      expect(described_class.new(Query.new(highlighting_mode: :inline)).to_h).to include(highlightingMode: "inline")
    end
  end
end
