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

RSpec.describe Projects::Exports::Formatters::BudgetSpentRatio do
  let(:project) { create(:project) }
  let(:aggregation_double) { instance_double(Budgets::ProjectBudgetAggregation) }
  let(:aggregation_class) { Budgets::ProjectBudgetAggregation }
  let(:user_with_permission) { create(:user, member_with_permissions: { project => [:view_budgets] }) }
  let(:user_without_permission) { create(:user) }

  before do
    allow(aggregation_class).to receive(:new).with(project).and_return(aggregation_double)
  end

  describe ".apply?" do
    it "returns true for :budget_spent_ratio" do
      expect(described_class.apply?(:budget_spent_ratio, :csv)).to be true
      expect(described_class.apply?(:budget_spent_ratio, :pdf)).to be true
    end

    it "returns false for other attributes" do
      expect(described_class.apply?(:budget_spent, :pdf)).to be false
      expect(described_class.apply?(:budget_planned, :unknown)).to be false
    end
  end

  describe "#format" do
    it "returns nil when the spent ratio is not available" do
      allow(aggregation_double).to receive(:total_ratio).and_return(nil)
      instance = described_class.new(:budget_spent_ratio)

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
        allow(aggregation_double).to receive(:total_ratio).and_return(42.7)
        instance = described_class.new(:budget_spent_ratio)

        expect(instance.format(project)).to be_nil
      end
    end

    context "with user with permission" do
      before do
        User.current = user_with_permission
      end

      it "formats the spent ratio percentage" do
        allow(aggregation_double).to receive(:total_ratio).and_return(42.7)
        instance = described_class.new(:budget_spent_ratio)

        expect(instance.format(project)).to eq(0.43)
      end
    end
  end
end
