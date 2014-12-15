#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'spec_helper'

describe ::API::V3::WorkPackages::WorkPackageRepresenter do
  let(:project) { FactoryGirl.create(:project) }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_time_entries,
                                                       :view_cost_entries,
                                                       :view_cost_rates,
                                                       :view_work_packages]) }
  let(:own_time_entries_role) { FactoryGirl.create(:role, permissions: [:view_time_entries,
                                                                        :view_cost_entries,
                                                                        :view_cost_rates,
                                                                        :view_work_packages]) }
  let(:user) { FactoryGirl.create(:user,
                                  member_in_project: project,
                                  member_through_role: role) }

  let(:cost_object) { FactoryGirl.create(:cost_object, project: project) }
  let(:cost_entry_1) { FactoryGirl.create(:cost_entry,
                                          work_package: work_package,
                                          project: project,
                                          units: 3,
                                          spent_on: Date.today,
                                          user: user,
                                          comments: "Entry 1") }
  let(:cost_entry_2) { FactoryGirl.create(:cost_entry,
                                          work_package: work_package,
                                          project: project,
                                          units: 3,
                                          spent_on: Date.today,
                                          user: user,
                                          comments: "Entry 2") }

  let(:work_package) { FactoryGirl.create(:work_package,
                                          project_id: project.id,
                                          cost_object: cost_object) }
  let(:representer) { described_class.new(work_package, current_user: user) }


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
      it { should have_json_path('spentTime') }

      it { should_not have_json_path('spentHours') }

      it { should have_json_path('overallCosts') }

      describe 'embedded' do
        it { should have_json_path('_embedded/costObject') }

        it { should have_json_path('_embedded/summarizedCostEntries') }
      end

      describe 'spentHours' do
        context 'time entry with single hour' do
          let(:time_entry) {
            FactoryGirl.create(:time_entry,
                               project: work_package.project,
                               work_package: work_package,
                               hours: 1.0)
          }

          before { time_entry }

          it { is_expected.to be_json_eql('PT1H'.to_json).at_path('spentTime') }
        end

        context 'time entry with multiple hours' do
          let(:time_entry) {
            FactoryGirl.create(:time_entry,
                               project: work_package.project,
                               work_package: work_package,
                               hours: 42.5)
          }

          before { time_entry }

          it { is_expected.to be_json_eql('P1DT18H30M'.to_json).at_path('spentTime') }
        end

        context 'no view_time_entries permission' do
          before do
            allow(user).to receive(:allowed_to?).and_return false
          end

          it { should_not have_json_path('spentTime') }
        end

        context 'only view_own_time_entries permission' do
          let(:own_time_entries_role) { FactoryGirl.create(:role, permissions: [:view_own_time_entries,
                                                                                :view_work_packages]) }

          let(:user2) { FactoryGirl.create(:user,
                                           member_in_project: project,
                                           member_through_role: own_time_entries_role) }

          let!(:own_time_entry) {
            FactoryGirl.create(:time_entry,
                               project: work_package.project,
                               work_package: work_package,
                               hours: 2,
                               user: user2)
          }

          let!(:other_time_entry) {
            FactoryGirl.create(:time_entry,
                               project: work_package.project,
                               work_package: work_package,
                               hours: 1,
                               user: user)
          }

          before do
            allow(User).to receive(:current).and_return(user2)
          end

          it { is_expected.to be_json_eql('PT2H'.to_json).at_path('spentTime') }
        end

        context 'no time entry' do
          it { is_expected.to be_json_eql('PT0S'.to_json).at_path('spentTime') }
        end
      end
    end
  end

  describe '_links' do
    describe 'move' do
      it_behaves_like 'action link' do
        let(:action) { 'log_costs' }
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
      project.enabled_module_names = project.enabled_module_names - ['costs_module']
      project.save!
    end

    describe 'work_package' do
      it { should have_json_path('spentTime') }

      it { should_not have_json_path('spentHours') }

      it { should_not have_json_path('overallCosts') }

      describe 'embedded' do
        it { should_not have_json_path('_embedded/costObject') }

        it { should_not have_json_path('_embedded/summarizedCostEntries') }
      end
    end

    describe '_links' do
      it { should_not have_json_path('_links/log_costs') }
    end
  end
end
