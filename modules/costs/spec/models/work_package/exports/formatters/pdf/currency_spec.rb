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

require "spec_helper"

RSpec.describe WorkPackage::Exports::Formatters::PDF::Currency,
               with_settings: { costs_currency: "EUR", costs_currency_format: "%n %u" } do
  let(:formatter_instance) { described_class.new(:labor_costs) }

  describe ".apply?" do
    it "returns true for the cost attributes and pdf format", :aggregate_failures do
      %i[material_costs labor_costs overall_costs].each do |attribute|
        expect(described_class.apply?(attribute, :pdf)).to be true
      end
    end

    it "returns false for labor_costs and csv format" do
      expect(described_class.apply?(:labor_costs, :csv)).to be false
    end

    it "returns false for other attributes" do
      expect(described_class.apply?(:estimated_hours, :pdf)).to be false
    end
  end

  describe "registration" do
    it "is the formatter picked for cost attributes in pdf exports" do
      expect(Exports::Register.formatter_for(WorkPackage, :overall_costs, :pdf)).to be_a(described_class)
    end
  end

  describe "#format_value" do
    it "returns the value in the configured currency" do
      expect(formatter_instance.format_value(1234.5, {})).to eq("1,234.50 EUR")
    end

    it "returns an empty string for zero" do
      expect(formatter_instance.format_value(0, {})).to eq("")
    end

    it "returns an empty string for nil" do
      expect(formatter_instance.format_value(nil, {})).to eq("")
    end
  end
end
