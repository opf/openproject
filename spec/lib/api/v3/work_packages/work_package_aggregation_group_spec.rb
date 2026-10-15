# frozen_string_literal: true

# -- copyright
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

require "spec_helper"

RSpec.describe API::V3::WorkPackages::WorkPackageAggregationGroup do
  include API::V3::Utilities::PathHelper

  subject(:represented) { described_class.new(group_key, 2, query:, current_user:).to_json }

  let(:project) { build_stubbed(:project) }
  let(:group_key) { project }
  let(:query) { build_stubbed(:query, group_by: "project") }
  let(:current_user) { build_stubbed(:user) }

  it "represents a scalar project group with its value and links", :aggregate_failures do
    expect(represented).to be_json_eql(project.name.to_json).at_path("value")
    expect(represented).to be_json_eql(2.to_json).at_path("count")
    expect(represented).to be_json_eql(
      [{ href: api_v3_paths.project(project.id) }].to_json
    ).at_path("_links/valueLink")
    expect(represented).to be_json_eql(
      api_v3_paths.query_group_by("project").to_json
    ).at_path("_links/groupBy/href")
  end

  context "with an unassigned group" do
    let(:group_key) { nil }

    it "represents the empty value and link" do
      expect(represented).to be_json_eql(nil.to_json).at_path("value")
      expect(represented).to be_json_eql([{ href: nil }].to_json).at_path("_links/valueLink")
    end
  end
end
