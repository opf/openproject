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

RSpec.describe Costs::QueryCurrencySelect, type: :model do
  let(:project) do
    build_stubbed(:project).tap do |p|
      allow(p)
        .to receive(:costs_enabled?)
        .and_return(costs_enabled)
    end
  end
  let(:instance) { described_class.instances(project).detect { |c| c.name == column_name } }
  let(:costs_enabled) { true }
  let(:column_name) { :material_costs }

  describe ".instances" do
    subject { described_class.instances(project).map(&:name) }

    context "with costs enabled" do
      it "returns the four costs columns" do
        expect(subject)
          .to match_array %i[budget material_costs labor_costs overall_costs]
      end
    end

    context "with costs disabled" do
      let(:costs_enabled) { false }

      it "returns no columns" do
        expect(subject)
          .to be_empty
      end
    end

    context "with no context" do
      it "returns the four costs columns" do
        expect(subject)
          .to match_array %i[budget material_costs labor_costs overall_costs]
      end
    end
  end

  context "material_costs" do
    describe "#summable?" do
      it "is true" do
        expect(instance)
          .to be_summable
      end
    end

    describe "#summable" do
      it "is callable" do
        expect(instance.summable)
          .to respond_to(:call)
      end

      # Not testing the results here, this is done by an integration test
      it "returns an AR scope that has an id and a material_costs column" do
        query = double("query")
        result = double("result")

        allow(query)
          .to receive(:results)
          .and_return result

        allow(result)
          .to receive(:work_packages)
          .and_return(WorkPackage.all)

        allow(query)
          .to receive(:group_by_statement)
          .and_return("author_id")

        expect(ActiveRecord::Base.connection.select_all(instance.summable.(query, true).to_sql).columns)
          .to match_array %w(id material_costs)
      end
    end
  end

  context "labor_costs" do
    let(:column_name) { :labor_costs }

    describe "#summable?" do
      it "is true" do
        expect(instance)
          .to be_summable
      end
    end

    describe "#summable" do
      it "is callable" do
        expect(instance.summable)
          .to respond_to(:call)
      end

      # Not testing the results here, this is done by an integration test
      it "returns an AR scope that has an id and a labor_costs column" do
        query = double("query")
        result = double("result")

        allow(query)
          .to receive(:results)
          .and_return result

        allow(result)
          .to receive(:work_packages)
          .and_return(WorkPackage.all)

        allow(query)
          .to receive(:group_by_statement)
          .and_return("author_id")

        expect(ActiveRecord::Base.connection.select_all(instance.summable.(query, true).to_sql).columns)
          .to match_array %w(id labor_costs)
      end
    end
  end
end
