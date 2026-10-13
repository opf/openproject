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

RSpec.describe WorkPackage::Exports::Formatters::SpentUnits do
  let(:formatter_instance) { described_class.new(:costs_by_type) }
  let(:work_package) { build_stubbed(:work_package) }
  let(:hours) { build_stubbed(:cost_type, unit: "hour", unit_plural: "hours") }
  let(:tickets) { build_stubbed(:cost_type, unit: "ticket", unit_plural: "tickets") }
  let(:summarized_cost_entries) { {} }

  before do
    attributes_helper = instance_double(Costs::AttributesHelper, summarized_cost_entries:)
    allow(Costs::AttributesHelper).to receive(:new).with(work_package, User.current).and_return(attributes_helper)
  end

  describe ".apply?" do
    it "returns true for costs_by_type and spent_units in any format", :aggregate_failures do
      %i[csv pdf].each do |format|
        expect(described_class.apply?(:costs_by_type, format)).to be true
        expect(described_class.apply?(:spent_units, format)).to be true
      end
    end

    it "returns false for other attributes" do
      expect(described_class.apply?(:labor_costs, :csv)).to be false
    end
  end

  describe "registration" do
    it "is the formatter picked for costs_by_type" do
      expect(Exports::Register.formatter_for(WorkPackage, :costs_by_type, :csv)).to be_a(described_class)
    end
  end

  describe "#format" do
    context "without cost entries" do
      it "returns nil" do
        expect(formatter_instance.format(work_package)).to be_nil
      end
    end

    context "with cost entries for several cost types" do
      let(:summarized_cost_entries) { { hours => BigDecimal("1.0"), tickets => BigDecimal("3.5") } }

      it "joins the volumes, using the singular unit for a volume of one" do
        expect(formatter_instance.format(work_package)).to eq("1.0 hour, 3.5 tickets")
      end
    end
  end
end
