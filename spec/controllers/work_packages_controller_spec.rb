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

describe WorkPackagesController, type: :controller do
  let(:project) { FactoryGirl.create(:project) }
  let(:current_user) { FactoryGirl.create(:user) }
  let(:query) { FactoryGirl.build_stubbed(:query).tap(&:add_default_filter) }
  let(:work_packages) { double("work packages").as_null_object }

  before do
    allow(User).to receive(:current).and_return current_user
    allow(User.current).to receive(:allowed_to?).and_return(true)
  end

  describe 'settings passed to front-end client' do
    describe 'visible attributes' do
      let(:call_action) { get('index', project_id: project.id) }
      let(:costs_attributes) { [:costObject, :spentHoursLinked, :overallCosts, :spentUnits] }

      subject { assigns(:enabled_default_work_package_properties) }

      context 'costs module disabled' do
        before do
          allow_any_instance_of(Project).to receive(:module_enabled?).and_return(true)
          allow_any_instance_of(Project).to receive(:module_enabled?).with(:costs_module).and_return(false)

          call_action
        end

        it { expect(subject).not_to include(*costs_attributes) }

        it { expect(subject).to include(:spentTime) }
      end

      context 'all permissions granted' do
        before { call_action }

        it { expect(subject).to include(*costs_attributes) }

        it { expect(subject).not_to include(:spentTime) }
      end

      context 'costs permissions revoked' do
        before do
          allow(User.current).to receive(:allowed_to?).with(:view_time_entries, anything).and_return(false)
          allow(User.current).to receive(:allowed_to?).with(:view_own_time_entries, anything).and_return(false)
          allow(User.current).to receive(:allowed_to?).with(:view_cost_entries, anything).and_return(false)
          allow(User.current).to receive(:allowed_to?).with(:view_own_cost_entries, anything).and_return(false)

          call_action
        end

        it { expect(subject).not_to include(:spentHoursLinked, :spentUnits) }
      end
    end
  end
end
