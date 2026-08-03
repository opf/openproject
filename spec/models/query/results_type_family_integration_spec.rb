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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

require "spec_helper"

# Users see one type per family, so a cross-project list has to treat a root and the
# variants other projects run as that single type when grouping, sorting and filtering.
RSpec.describe Query::Results, "type families", with_flag: { type_variants: true } do
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:user) { create(:admin) }

  shared_let(:alpha) { create(:type, name: "Alpha") }
  shared_let(:bug) { create(:type, name: "Bug", position: alpha.position + 1) }
  shared_let(:variant) { create(:type, name: "Mobile Bug", parent: bug) }
  shared_let(:zulu) { create(:type, name: "Zulu", position: bug.position + 1) }

  shared_let(:project) { create(:project, types: [alpha, bug, zulu]) }
  shared_let(:variant_project) { create(:project, types: [variant]) }

  shared_let(:alpha_work_package) { create(:work_package, project:, type: alpha) }
  shared_let(:root_work_package) { create(:work_package, project:, type: bug) }
  shared_let(:zulu_work_package) { create(:work_package, project:, type: zulu) }
  shared_let(:variant_work_package) { create(:work_package, project: variant_project, type: variant) }

  current_user { user }

  def query_with(**attributes)
    build(:query, user:, project: nil, **attributes).tap { |query| query.filters.clear }
  end

  describe "grouping by type" do
    subject(:groups) { query_with(group_by: "type").results.work_package_count_by_group }

    it "groups a root and its variants together, under the root" do
      expect(groups).to eq(alpha => 1, bug => 2, zulu => 1)
    end

    it "does not offer a group per variant" do
      expect(groups.keys.map(&:own_name)).not_to include("Mobile Bug")
    end

    it "sums the group without raising" do
      query = query_with(group_by: "type", display_sums: true)

      expect { query.results.all_group_sums }.not_to raise_error
    end
  end

  describe "sorting by type" do
    subject(:sorted_ids) do
      query_with.tap { |query| query.sort_criteria = [%w[type asc]] }.results.work_packages.map(&:id)
    end

    # A variant's own position is append order within its family, so sorting by it would
    # place the variant anywhere.
    it "sorts a variant in the position of its root" do
      expect(sorted_ids.index(variant_work_package.id)).to be > sorted_ids.index(alpha_work_package.id)
      expect(sorted_ids.index(variant_work_package.id)).to be < sorted_ids.index(zulu_work_package.id)
    end
  end

  describe "filtering by type" do
    def results_for(type)
      query_with.tap { |query| query.add_filter("type_id", "=", [type.id.to_s]) }.results.work_packages
    end

    it "finds the whole family when filtering for the root" do
      expect(results_for(bug)).to contain_exactly(root_work_package, variant_work_package)
    end

    it "finds the whole family when filtering for the variant a project offers" do
      expect(results_for(variant)).to contain_exactly(root_work_package, variant_work_package)
    end

    it "leaves other families out" do
      expect(results_for(alpha)).to contain_exactly(alpha_work_package)
    end
  end
end
