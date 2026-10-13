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

require "rails_helper"

RSpec.describe Projects::Exports::Formatters::BudgetCurrencyAttribute do
  let(:project) { create(:project) }
  let(:aggregation_double) { instance_double(Budgets::ProjectBudgetAggregation) }
  let(:aggregation_class) { Budgets::ProjectBudgetAggregation }
  let(:user_with_permission) { create(:user, member_with_permissions: { project => [:view_budgets] }) }
  let(:user_without_permission) { create(:user) }

  before do
    allow(aggregation_class).to receive(:new).with(project).and_return(aggregation_double)
  end

  describe ".apply?" do
    it "returns true for supported budget attributes" do
      expect(described_class.apply?(:budget_available, :csv)).to be true
      expect(described_class.apply?(:budget_spent, :csv)).to be true
      expect(described_class.apply?(:budget_planned, :csv)).to be true
      expect(described_class.apply?(:budget_available, :pdf)).to be true
      expect(described_class.apply?(:budget_spent, :pdf)).to be true
      expect(described_class.apply?(:budget_planned, :pdf)).to be true
    end

    it "returns false for unsupported attributes" do
      expect(described_class.apply?(:budget_spent_ratio, :csv)).to be false
    end
  end

  describe "#format" do
    it "returns nil when the an attribute is not available" do
      allow(aggregation_double).to receive(:total_available).and_return(42.7)
      instance = described_class.new(:budget_available)

      expect(instance.format(project)).to be_nil
    end

    it "returns nil when the budget aggregation is not available" do
      allow(aggregation_class).to receive(:new).with(project).and_return(nil)
      instance = described_class.new(:budget_spent_ratio)

      expect(instance.format(project)).to be_nil
    end

    context "with user without permission" do
      before do
        User.current = user_without_permission
      end

      it "returns nil" do
        allow(aggregation_double).to receive(:total_available).and_return(42.7)
        instance = described_class.new(:budget_available)

        expect(instance.format(project)).to be_nil
      end
    end

    context "with user with permission" do
      before do
        User.current = user_with_permission
      end

      it "returns the raw budget available value" do
        allow(aggregation_double).to receive(:total_available).and_return(42.7)
        instance = described_class.new(:budget_available)

        expect(instance.format(project)).to eq(42.7)
      end

      it "returns the raw budget spent value" do
        allow(aggregation_double).to receive(:total_spent).and_return(42.7)
        instance = described_class.new(:budget_spent)

        expect(instance.format(project)).to eq(42.7)
      end

      it "returns the raw budget planned value" do
        allow(aggregation_double).to receive(:total_planned).and_return(42.7)
        instance = described_class.new(:budget_planned)

        expect(instance.format(project)).to eq(42.7)
      end
    end
  end

  describe "#format_options" do
    let(:instance) { described_class.new(:budget_available) }

    it "returns currency format options" do
      with_settings(costs_currency: "USD", costs_currency_format: "%n %u") do
        expected_format = "#,##0.00 [$USD]"
        expect(instance.format_options).to eq({ number_format: expected_format })
      end
    end

    it "handles different currency settings" do
      with_settings(costs_currency: "EUR", costs_currency_format: "%u %n") do
        expected_format = "[$EUR] #,##0.00"
        expect(instance.format_options).to eq({ number_format: expected_format })
      end
    end
  end
end
