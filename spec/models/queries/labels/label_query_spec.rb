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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Queries::Labels::LabelQuery do
  shared_let(:admin) { create(:admin) }

  shared_let(:banana) { create(:label, name: "banana") }
  shared_let(:apple) { create(:label, name: "Apple") }
  shared_let(:cherry) { create(:label, name: "cherry") }

  let(:instance) { described_class.new(user: admin) }

  describe "#results" do
    it "orders labels case-insensitively by name" do
      expect(instance.results.to_a).to eq([apple, banana, cherry])
    end

    it "exposes the usage count of each label" do
      create(:labeling, label: apple)

      counts = instance.results.index_by(&:id).transform_values(&:usage_count)

      expect(counts).to eq(apple.id => 1, banana.id => 0, cherry.id => 0)
    end

    it "paginates with a correct scalar total" do
      expect(instance.results.paginate(page: 1, per_page: 1).total_entries).to eq(3)
    end
  end

  describe "via ParamsToQueryService" do
    it "applies the name filter parsed from JSON params" do
      params = ActionController::Parameters.new(
        filters: [{ name: { operator: "~", values: ["app"] } }].to_json
      )

      query = ParamsToQueryService.new(Label, admin, query_class: described_class).call(params)

      expect(query.results.to_a).to eq([apple])
    end

    it "rejects the = operator without raising on results" do
      params = ActionController::Parameters.new(
        filters: [{ name: { operator: "=", values: ["x"] } }].to_json
      )

      query = ParamsToQueryService.new(Label, admin, query_class: described_class).call(params)

      expect(query.valid?).to be false
      expect { query.results.to_a }.not_to raise_error
    end
  end
end
