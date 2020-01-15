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

require 'spec_helper'

describe ::API::V3::WorkPackages::WorkPackageRepresenter do
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryBot.create(:project) }
  let(:role) do
    FactoryBot.create(:role, permissions: [:view_time_entries,
                                            :view_cost_entries,
                                            :view_cost_rates,
                                            :view_work_packages])
  end
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end

  let(:cost_object) { FactoryBot.create(:cost_object, project: project) }
  let(:cost_entry_1) do
    FactoryBot.create(:cost_entry,
                      work_package: work_package,
                      project: project,
                      units: 3,
                      spent_on: Date.today,
                      user: user,
                      comments: 'Entry 1')
  end
  let(:cost_entry_2) do
    FactoryBot.create(:cost_entry,
                      work_package: work_package,
                      project: project,
                      units: 3,
                      spent_on: Date.today,
                      user: user,
                      comments: 'Entry 2')
  end

  let(:work_package) do
    FactoryBot.create(:work_package,
                      project_id: project.id,
                      cost_object: cost_object)
  end
  let(:representer) do
    described_class.new(work_package,
                        current_user: user,
                        embed_links: true)
  end

  before(:each) do
    allow(User).to receive(:current).and_return user
  end

  subject(:generated) { representer.to_json }

  describe 'generation' do
    before do
      cost_entry_1
      cost_entry_2
    end

    describe 'work_package' do
      # specifiying as it used to be different
      it { is_expected.to have_json_path('spentTime') }

      it { is_expected.not_to have_json_path('spentHours') }

      it { is_expected.to have_json_path('overallCosts') }

      describe 'budget' do
        before do
          allow(representer)
            .to receive(:cost_object_visible?)
            .and_return(true)
        end

        it_behaves_like 'has a titled link' do
          let(:link) { 'costObject' }
          let(:href) { "/api/v3/budgets/#{cost_object.id}" }
          let(:title) { cost_object.subject }
        end

        it 'has the budget embedded' do
          is_expected.to be_json_eql(cost_object.subject.to_json)
            .at_path('_embedded/costObject/subject')
        end
      end

      it_behaves_like 'has an untitled link' do
        let(:link) { 'costsByType' }
        let(:href) { api_v3_paths.summarized_work_package_costs_by_type work_package.id }
      end

      it 'embeds the costsByType' do
        is_expected.to have_json_path('_embedded/costsByType')
      end

      describe 'spentTime' do
        context 'time entry with single hour' do
          let(:time_entry) do
            FactoryBot.create(:time_entry,
                              project: work_package.project,
                              work_package: work_package,
                              hours: 1.0)
          end

          before { time_entry }

          it { is_expected.to be_json_eql('PT1H'.to_json).at_path('spentTime') }
        end

        context 'time entry with multiple hours' do
          let(:time_entry) do
            FactoryBot.create(:time_entry,
                              project: work_package.project,
                              work_package: work_package,
                              hours: 42.5)
          end

          before { time_entry }

          it { is_expected.to be_json_eql('P1DT18H30M'.to_json).at_path('spentTime') }
        end

        context 'no view_time_entries permission' do
          before do
            allow(user).to receive(:allowed_to?).and_return false
          end

          it { is_expected.not_to have_json_path('spentTime') }
        end

        context 'only view_own_time_entries permission' do
          let(:own_time_entries_role) do
            FactoryBot.create(:role, permissions: [:view_own_time_entries,
                                                    :view_work_packages])
          end

          let(:user2) do
            FactoryBot.create(:user,
                              member_in_project: project,
                              member_through_role: own_time_entries_role)
          end

          let!(:own_time_entry) do
            FactoryBot.create(:time_entry,
                              project: work_package.project,
                              work_package: work_package,
                              hours: 2,
                              user: user2)
          end

          let!(:other_time_entry) do
            FactoryBot.create(:time_entry,
                              project: work_package.project,
                              work_package: work_package,
                              hours: 1,
                              user: user)
          end

          before do
            allow(User).to receive(:current).and_return(user2)
          end

          it { is_expected.to be_json_eql('PT2H'.to_json).at_path('spentTime') }
        end

        context 'no time entry' do
          it { is_expected.to be_json_eql('PT0S'.to_json).at_path('spentTime') }
        end
      end

      describe 'laborCosts' do
        before do
          allow(user).to receive(:allowed_to?).and_return false
        end

        before do
          allow(work_package).to receive(:labor_costs).and_return(6000.0)
        end

        context 'with the :view_hourly_rates and :view_time_entries permission' do
          before do
            allow(user)
              .to receive(:allowed_to?)
              .with(:view_time_entries, work_package.project)
              .and_return true

            allow(user)
              .to receive(:allowed_to?)
              .with(:view_hourly_rates, work_package.project)
              .and_return true
          end

          it 'is expected to have a laborCosts attribute' do
            is_expected.to be_json_eql('6,000.00 EUR'.to_json).at_path('laborCosts')
          end
        end

        context 'with the :view_own_hourly_rate and :view_own_time_entries permission' do
          before do
            allow(user)
              .to receive(:allowed_to?)
              .with(:view_own_time_entries, cost_object.project)
              .and_return true

            allow(user)
              .to receive(:allowed_to?)
              .with(:view_own_hourly_rate, cost_object.project)
              .and_return true
          end

          it 'is expected to have a laborCosts attribute' do
            is_expected.to be_json_eql('6,000.00 EUR'.to_json).at_path('laborCosts')
          end
        end

        context 'without the user having permission' do
          it 'has no attribute' do
            is_expected.not_to have_json_path('laborCosts')
          end
        end
      end

      describe 'materialCosts' do
        before do
          allow(user).to receive(:allowed_to?).and_return false
        end

        before do
          allow(work_package).to receive(:material_costs).and_return(6000.0)
        end

        context 'with the :view_own_cost_entries and :view_cost_rates permission' do
          before do
            allow(user)
              .to receive(:allowed_to?)
              .with(:view_own_cost_entries, work_package.project)
              .and_return true

            allow(user)
              .to receive(:allowed_to?)
              .with(:view_cost_rates, work_package.project)
              .and_return true
          end

          it 'is expected to have a materialCosts attribute' do
            is_expected.to be_json_eql('6,000.00 EUR'.to_json).at_path('materialCosts')
          end
        end

        context 'with the :view_cost_entries and :view_cost_rates permission' do
          before do
            allow(user)
              .to receive(:allowed_to?)
              .with(:view_cost_entries, cost_object.project)
              .and_return true

            allow(user)
              .to receive(:allowed_to?)
              .with(:view_cost_rates, work_package.project)
              .and_return true
          end

          it 'is expected to have a materialCosts attribute' do
            is_expected.to be_json_eql('6,000.00 EUR'.to_json).at_path('materialCosts')
          end
        end

        context 'without the user having permission' do
          it 'has no attribute' do
            is_expected.not_to have_json_path('materialCosts')
          end
        end
      end

      describe 'overallCosts' do
        before do
          allow(user).to receive(:allowed_to?).and_return false
        end

        before do
          allow(work_package).to receive(:overall_costs).and_return(6000.0)
        end

        context 'with the :view_hourly_rates and :view_time_entries permission' do
          before do
            allow(user)
              .to receive(:allowed_to?)
              .with(:view_time_entries, work_package.project)
              .and_return true

            allow(user)
              .to receive(:allowed_to?)
              .with(:view_hourly_rates, work_package.project)
              .and_return true
          end

          it 'is expected to have a overallCosts attribute' do
            is_expected.to be_json_eql('6,000.00 EUR'.to_json).at_path('overallCosts')
          end
        end

        context 'with the :view_own_hourly_rate and :view_own_time_entries permission' do
          before do
            allow(user)
              .to receive(:allowed_to?)
              .with(:view_own_time_entries, cost_object.project)
              .and_return true

            allow(user)
              .to receive(:allowed_to?)
              .with(:view_own_hourly_rate, cost_object.project)
              .and_return true
          end

          it 'is expected to have a overallCosts attribute' do
            is_expected.to be_json_eql('6,000.00 EUR'.to_json).at_path('overallCosts')
          end
        end

        context 'with the :view_own_cost_entries and :view_cost_rates permission' do
          before do
            allow(user)
              .to receive(:allowed_to?)
              .with(:view_own_cost_entries, work_package.project)
              .and_return true

            allow(user)
              .to receive(:allowed_to?)
              .with(:view_cost_rates, work_package.project)
              .and_return true
          end

          it 'is expected to have a overallCosts attribute' do
            is_expected.to be_json_eql('6,000.00 EUR'.to_json).at_path('overallCosts')
          end
        end

        context 'with the :view_cost_entries and :view_cost_rates permission' do
          before do
            allow(user)
              .to receive(:allowed_to?)
              .with(:view_cost_entries, cost_object.project)
              .and_return true

            allow(user)
              .to receive(:allowed_to?)
              .with(:view_cost_rates, work_package.project)
              .and_return true
          end

          it 'is expected to have a overallCosts attribute' do
            is_expected.to be_json_eql('6,000.00 EUR'.to_json).at_path('overallCosts')
          end
        end

        context 'without the user having permission' do
          it 'has no attribute' do
            is_expected.not_to have_json_path('overallCosts')
          end
        end
      end
    end
  end

  describe '_links' do
    describe 'move' do
      it_behaves_like 'action link' do
        let(:action) { 'logCosts' }
        let(:permission) { :log_costs }
      end
    end

    describe 'timeEntries' do
      it 'exists if user has view_time_entries permission' do
        allow(user).to receive(:allowed_to?).and_return false
        allow(user).to receive(:allowed_to?).with(:view_time_entries,
                                                  cost_object.project)
          .and_return true

        is_expected.to have_json_path('_links/timeEntries/href')
      end

      it 'has spentTime link when user only has view_own_time_entries permission' do
        allow(user).to receive(:allowed_to?).and_return false
        allow(user).to receive(:allowed_to?).with(:view_own_time_entries,
                                                  cost_object.project)
          .and_return true

        is_expected.to have_json_path('_links/timeEntries/href')
      end
    end
  end

  describe 'costs module disabled' do
    before do
      allow(work_package).to receive(:costs_enabled?).and_return false
    end

    describe 'work_package' do
      it { is_expected.to have_json_path('spentTime') }

      it { is_expected.not_to have_json_path('spentHours') }

      describe 'embedded' do
        it { is_expected.not_to have_json_path('_embedded/costObject') }

        it { is_expected.not_to have_json_path('_embedded/summarizedCostEntries') }
      end
    end

    describe '_links' do
      it { is_expected.not_to have_json_path('_links/log_costs') }
    end
  end

  describe '.to_eager_load' do
    it 'includes the cost objects' do
      expect(described_class.to_eager_load.any? do |el|
        el == :cost_object
      end).to be_truthy
    end
  end
end
