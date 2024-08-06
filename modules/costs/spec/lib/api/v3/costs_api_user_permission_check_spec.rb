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

RSpec.describe API::V3::CostsApiUserPermissionCheck do
  class CostsApiUserPermissionCheckTestClass
    # mimic representer
    def view_time_entries_allowed?
      current_user.allowed_in_project?(:view_time_entries, represented.project) ||
      current_user.allowed_in_project?(:view_own_time_entries, represented.project)
    end

    include API::V3::CostsApiUserPermissionCheck
  end

  let(:user) { build_stubbed(:user) }
  let(:view_time_entries) { false }
  let(:view_own_time_entries) { false }
  let(:view_hourly_rates) { false }
  let(:view_own_hourly_rate) { false }
  let(:view_cost_rates) { false }
  let(:view_own_cost_entries) { false }
  let(:view_cost_entries) { false }
  let(:view_budgets) { false }
  let(:project) { build_stubbed(:project) }
  let(:work_package) { build_stubbed(:work_package, project:) }

  before do
    without_partial_double_verification do
      allow(subject).to receive_messages(current_user: user, represented: work_package) # rubocop:disable RSpec/SubjectStub
    end

    mock_permissions_for(user) do |mock|
      mock.allow_in_project :view_time_entries, project: work_package.project if view_time_entries
      mock.allow_in_project :view_own_time_entries, project: work_package.project if view_own_time_entries
      mock.allow_in_project :view_hourly_rates, project: work_package.project if view_hourly_rates
      mock.allow_in_project :view_own_hourly_rate, project: work_package.project if view_own_hourly_rate
      mock.allow_in_project :view_cost_rates, project: work_package.project if view_cost_rates
      mock.allow_in_project :view_own_cost_entries, project: work_package.project if view_own_cost_entries
      mock.allow_in_project :view_cost_entries, project: work_package.project if view_cost_entries
      mock.allow_in_project :view_budgets, project: work_package.project if view_budgets
    end
  end

  subject { CostsApiUserPermissionCheckTestClass.new }

  describe "#overall_costs_visible?" do
    describe :overall_costs_visible? do
      shared_examples_for "not visible" do
        it "is not visible" do
          expect(subject).not_to be_overall_costs_visible
        end
      end

      shared_examples_for "is visible" do
        it "is not visible" do
          expect(subject).to be_overall_costs_visible
        end
      end

      context "lacks permissions" do
        it_behaves_like "not visible"
      end

      context "has view_time_entries and view_hourly_rates" do
        let(:view_time_entries) { true }
        let(:view_hourly_rates) { true }

        it_behaves_like "is visible"
      end

      context "has view_time_entries and view_own_hourly_rate" do
        let(:view_time_entries) { true }
        let(:view_own_hourly_rate) { true }

        it_behaves_like "is visible"
      end

      context "has view_own_time_entries and view_own_hourly_rate" do
        let(:view_own_time_entries) { true }
        let(:view_own_hourly_rate) { true }

        it_behaves_like "is visible"
      end

      context "has view_own_time_entries and view_hourly_rates" do
        let(:view_own_time_entries) { true }
        let(:view_hourly_rates) { true }

        it_behaves_like "is visible"
      end

      context "has view_cost_entries and view_cost_rates" do
        let(:view_cost_entries) { true }
        let(:view_cost_rates) { true }

        it_behaves_like "is visible"
      end

      context "has view_own_cost_entries and view_cost_rates" do
        let(:view_cost_entries) { true }
        let(:view_cost_rates) { true }

        it_behaves_like "is visible"
      end
    end

    describe :labor_costs_visible? do
      shared_examples_for "not visible" do
        it "is not visible" do
          expect(subject).not_to be_labor_costs_visible
        end
      end

      shared_examples_for "is visible" do
        it "is not visible" do
          expect(subject).to be_labor_costs_visible
        end
      end

      context "lacks permissions" do
        it_behaves_like "not visible"
      end

      context "has view_time_entries and view_hourly_rates" do
        let(:view_time_entries) { true }
        let(:view_hourly_rates) { true }

        it_behaves_like "is visible"
      end

      context "has view_own_time_entries and view_hourly_rates" do
        let(:view_own_time_entries) { true }
        let(:view_hourly_rates) { true }

        it_behaves_like "is visible"
      end
    end

    describe :material_costs_visible? do
      shared_examples_for "not visible" do
        it "is not visible" do
          expect(subject).not_to be_material_costs_visible
        end
      end

      shared_examples_for "is visible" do
        it "is not visible" do
          expect(subject).to be_material_costs_visible
        end
      end

      context "lacks permissions" do
        it_behaves_like "not visible"
      end

      context "has view_cost_entries and view_cost_rates" do
        let(:view_cost_entries) { true }
        let(:view_cost_rates) { true }

        it_behaves_like "is visible"
      end

      context "has view_own_cost_entries and view_own_cost_rates" do
        let(:view_own_cost_entries) { true }
        let(:view_cost_rates) { true }

        it_behaves_like "is visible"
      end
    end

    describe :costs_by_type_visible? do
      shared_examples_for "not visible" do
        it "is not visible" do
          expect(subject).not_to be_costs_by_type_visible
        end
      end

      shared_examples_for "is visible" do
        it "is not visible" do
          expect(subject).to be_costs_by_type_visible
        end
      end

      context "lacks permissions" do
        it_behaves_like "not visible"
      end

      context "has view_costs_entries" do
        let(:view_cost_entries) { true }

        it_behaves_like "is visible"
      end

      context "has view_own_time_entries" do
        let(:view_own_cost_entries) { true }

        it_behaves_like "is visible"
      end
    end

    context :spent_time_visible do
      shared_examples_for "not visible" do
        it "is not visible" do
          expect(subject).not_to be_spent_time_visible
        end
      end

      shared_examples_for "is visible" do
        it "is not visible" do
          expect(subject).to be_spent_time_visible
        end
      end

      context "lacks permissions" do
        it_behaves_like "not visible"
      end

      context "has view_costs_entries" do
        let(:view_time_entries) { true }

        it_behaves_like "is visible"
      end

      context "has view_own_time_entries" do
        let(:view_own_time_entries) { true }

        it_behaves_like "is visible"
      end
    end
  end
end
