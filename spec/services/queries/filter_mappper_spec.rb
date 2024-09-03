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

RSpec.describe Queries::Copy::FiltersMapper do
  let(:state) { Shared::ServiceState.new }
  let(:instance) { described_class.new(state, filters) }

  subject { instance.map_filters! }

  describe "with a query filters array" do
    let(:query) do
      query = build(:query)
      query.add_filter "parent", "=", ["1"]
      query.add_filter "category_id", "=", ["2"]
      query.add_filter "version_id", "=", ["3"]

      query
    end
    let(:filters) { query.filters }

    context "when mapping state exists" do
      before do
        state.work_package_id_lookup = { 1 => 11 }
        state.category_id_lookup = { 2 => 22 }
        state.version_id_lookup = { 3 => 33 }
      end

      it "maps the filters" do
        expect(subject[1].values).to eq(["11"])
        expect(subject[2].values).to eq(["22"])
        expect(subject[3].values).to eq(["33"])
      end
    end

    context "when mapping state does not exist" do
      it "does not map the filters" do
        expect(subject[1].values).to eq(["1"])
        expect(subject[2].values).to eq(["2"])
        expect(subject[3].values).to eq(["3"])
      end
    end
  end

  describe "with a filter hash array" do
    let(:filters) do
      [
        { "parent" => { "operator" => "=", "values" => ["1"] } },
        { "category_id" => { "operator" => "=", "values" => ["2"] } },
        { "version_id" => { "operator" => "=", "values" => ["3"] } }
      ]
    end

    context "when mapping state exists" do
      before do
        state.work_package_id_lookup = { 1 => 11 }
        state.category_id_lookup = { 2 => 22 }
        state.version_id_lookup = { 3 => 33 }
      end

      it "maps the filters" do
        expect(subject[0]["parent"]["values"]).to eq(["11"])
        expect(subject[1]["category_id"]["values"]).to eq(["22"])
        expect(subject[2]["version_id"]["values"]).to eq(["33"])
      end
    end

    context "when mapping state does not exist" do
      it "does not map the filters" do
        expect(subject[0]["parent"]["values"]).to eq(["1"])
        expect(subject[1]["category_id"]["values"]).to eq(["2"])
        expect(subject[2]["version_id"]["values"]).to eq(["3"])
      end
    end
  end

  describe "with a symbolized filter hash array" do
    let(:filters) do
      [
        { parent: { operator: "=", values: ["1"] } }
      ]
    end

    context "when mapping state exists" do
      before do
        state.work_package_id_lookup = { 1 => 11 }
        state.category_id_lookup = { 2 => 22 }
        state.version_id_lookup = { 3 => 33 }
      end

      it "maps the filters" do
        expect(subject[0]["parent"]["values"]).to eq(["11"])
      end
    end
  end
end
