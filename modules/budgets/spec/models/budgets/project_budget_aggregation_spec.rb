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

RSpec.describe Budgets::ProjectBudgetAggregation do
  let(:project) { create(:project, enabled_module_names: %i[budgets work_package_tracking]) }

  subject { described_class.new(project) }

  describe "#total_planned" do
    context "with multiple budgets" do
      let!(:budget1) { create(:budget, project:, base_amount: 1000) }
      let!(:budget2) { create(:budget, project:, base_amount: 2000) }

      it "sums up all budget amounts" do
        expect(subject.total_planned).to eq(budget1.budget + budget2.budget)
      end
    end

    context "with no budgets" do
      it "returns zero" do
        expect(subject.total_planned).to eq(BigDecimal(0))
      end
    end
  end

  describe "#total_spent" do
    context "with multiple budgets with spent amounts" do
      let!(:budget1) { create(:budget, project:) }
      let!(:budget2) { create(:budget, project:) }

      it "sums up all spent amounts" do
        expect(subject.total_spent).to eq(budget1.spent + budget2.spent)
      end
    end

    context "with no budgets" do
      it "returns zero" do
        expect(subject.total_spent).to eq(BigDecimal(0))
      end
    end
  end

  describe "#total_available" do
    context "with multiple budgets with available amounts" do
      let!(:budget1) { create(:budget, project:) }
      let!(:budget2) { create(:budget, project:) }

      it "sums up all available amounts" do
        expect(subject.total_available).to eq(budget1.available + budget2.available)
      end
    end

    context "with no budgets" do
      it "returns zero" do
        expect(subject.total_available).to eq(BigDecimal(0))
      end
    end
  end

  describe "#total_ratio" do
    before do
      allow(project)
        .to receive(:budgets)
        .and_return([instance_double(Budget, budget: BigDecimal(planned), spent: BigDecimal(spent))])
    end

    context "when total planned is greater than zero" do
      let(:planned) { 1000 }
      let(:spent) { 250 }

      it "returns the percentage ratio rounded" do
        expect(subject.total_ratio).to eq(25)
      end
    end

    context "when total planned is zero" do
      let(:planned) { 0 }
      let(:spent) { 100 }

      it "returns zero" do
        expect(subject.total_ratio).to eq(0)
      end
    end

    context "with decimal ratio" do
      let(:planned) { 3000 }
      let(:spent) { 1000 }

      it "rounds to the nearest integer" do
        expect(subject.total_ratio).to eq(33)
      end
    end
  end

  describe "#budgets" do
    context "with budgets in the project" do
      let!(:budget1) { create(:budget, project:) }
      let!(:budget2) { create(:budget, project:) }

      it "returns all project budgets as an array" do
        expect(subject.budgets).to contain_exactly(budget1, budget2)
      end

      it "memoizes the result" do
        first_call = subject.budgets
        second_call = subject.budgets
        expect(first_call).to be(second_call)
      end
    end

    context "with no budgets" do
      it "returns an empty array" do
        expect(subject.budgets).to eq([])
      end
    end
  end
end
