#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../../../spec_helper', __FILE__)

describe API::V3::CostsApiUserPermissionCheck do
  class CostsApiUserPermissionCheckTestClass
    include API::V3::CostsApiUserPermissionCheck
  end

  let(:user) { mock_model('User') }
  let(:project) { mock_model('Project') }
  let(:work_package) { mock_model('WorkPackage', project: project) }

  before do
    allow(subject)
      .to receive(:current_user)
      .and_return(user)
    allow(subject)
      .to receive(:represented)
      .and_return(work_package)
  end

  subject { CostsApiUserPermissionCheckTestClass.new }

  let(:view_time_entries) { false }
  let(:view_own_time_entries) { false }
  let(:view_hourly_rates) { false }
  let(:view_own_hourly_rate) { false }
  let(:view_cost_rates) { false }
  let(:view_own_cost_entries) { false }
  let(:view_cost_entries) { false }
  let(:view_cost_objects) { false }

  before do
    [:view_time_entries,
     :view_own_time_entries,
     :view_hourly_rates,
     :view_own_hourly_rate,
     :view_cost_rates,
     :view_own_cost_entries,
     :view_cost_entries,
     :view_cost_objects].each do |permission|

      allow(subject)
        .to receive(:current_user_allowed_to)
        .with(permission, context: work_package.project)
        .and_return send(permission)
    end
  end

  describe '#overall_costs_visible?' do

    describe :overall_costs_visible? do
      shared_examples_for 'not visible' do
        it 'is not visible' do
          is_expected.to_not be_overall_costs_visible
        end
      end

      shared_examples_for 'is visible' do
        it 'is not visible' do
          is_expected.to be_overall_costs_visible
        end
      end

      context 'lacks permissions' do
        it_behaves_like 'not visible'
      end

      context 'has view_time_entries and view_hourly_rates' do
        let(:view_time_entries) { true }
        let(:view_hourly_rates) { true }

        it_behaves_like 'is visible'
      end

      context 'has view_time_entries and view_own_hourly_rate' do
        let(:view_time_entries) { true }
        let(:view_own_hourly_rate) { true }

        it_behaves_like 'is visible'
      end

      context 'has view_own_time_entries and view_own_hourly_rate' do
        let(:view_own_time_entries) { true }
        let(:view_own_hourly_rate) { true }

        it_behaves_like 'is visible'
      end

      context 'has view_own_time_entries and view_hourly_rates' do
        let(:view_own_time_entries) { true }
        let(:view_hourly_rates) { true }

        it_behaves_like 'is visible'
      end

      context 'has view_cost_entries and view_cost_rates' do
        let(:view_cost_entries) { true }
        let(:view_cost_rates) { true }

        it_behaves_like 'is visible'
      end

      context 'has view_own_cost_entries and view_cost_rates' do
        let(:view_cost_entries) { true }
        let(:view_cost_rates) { true }

        it_behaves_like 'is visible'
      end
    end

    describe :labor_costs_visible? do
      shared_examples_for 'not visible' do
        it 'is not visible' do
          is_expected.to_not be_labor_costs_visible
        end
      end

      shared_examples_for 'is visible' do
        it 'is not visible' do
          is_expected.to be_labor_costs_visible
        end
      end

      context 'lacks permissions' do
        it_behaves_like 'not visible'
      end

      context 'has view_time_entries and view_hourly_rates' do
        let(:view_time_entries) { true }
        let(:view_hourly_rates) { true }

        it_behaves_like 'is visible'
      end

      context 'has view_own_time_entries and view_hourly_rates' do
        let(:view_own_time_entries) { true }
        let(:view_hourly_rates) { true }

        it_behaves_like 'is visible'
      end
    end

    describe :material_costs_visible? do
      shared_examples_for 'not visible' do
        it 'is not visible' do
          is_expected.to_not be_material_costs_visible
        end
      end

      shared_examples_for 'is visible' do
        it 'is not visible' do
          is_expected.to be_material_costs_visible
        end
      end

      context 'lacks permissions' do
        it_behaves_like 'not visible'
      end

      context 'has view_cost_entries and view_cost_rates' do
        let(:view_cost_entries) { true }
        let(:view_cost_rates) { true }

        it_behaves_like 'is visible'
      end

      context 'has view_own_cost_entries and view_own_cost_rates' do
        let(:view_own_cost_entries) { true }
        let(:view_cost_rates) { true }

        it_behaves_like 'is visible'
      end
    end

    describe :costs_by_type_visible? do
      shared_examples_for 'not visible' do
        it 'is not visible' do
          is_expected.to_not be_costs_by_type_visible
        end
      end

      shared_examples_for 'is visible' do
        it 'is not visible' do
          is_expected.to be_costs_by_type_visible
        end
      end

      context 'lacks permissions' do
        it_behaves_like 'not visible'
      end

      context 'has view_costs_entries' do
        let(:view_cost_entries) { true }

        it_behaves_like 'is visible'
      end

      context 'has view_own_time_entries' do
        let(:view_own_cost_entries) { true }

        it_behaves_like 'is visible'
      end
    end

    context :spent_time_visible do
      shared_examples_for 'not visible' do
        it 'is not visible' do
          is_expected.to_not be_spent_time_visible
        end
      end

      shared_examples_for 'is visible' do
        it 'is not visible' do
          is_expected.to be_spent_time_visible
        end
      end

      context 'lacks permissions' do
        it_behaves_like 'not visible'
      end

      context 'has view_costs_entries' do
        let(:view_time_entries) { true }

        it_behaves_like 'is visible'
      end

      context 'has view_own_time_entries' do
        let(:view_own_time_entries) { true }

        it_behaves_like 'is visible'
      end
    end

    context :cost_object_visible? do
      shared_examples_for 'not visible' do
        it 'is not visible' do
          is_expected.to_not be_cost_object_visible
        end
      end

      shared_examples_for 'is visible' do
        it 'is not visible' do
          is_expected.to be_cost_object_visible
        end
      end

      context 'lacks permissions' do
        it_behaves_like 'not visible'
      end

      context 'has view_costs_entries' do
        let(:view_cost_objects) { true }

        it_behaves_like 'is visible'
      end
    end
  end
end
