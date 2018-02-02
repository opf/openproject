#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe CustomActions::UpdateWorkPackageService do
  let(:custom_action) do
    action = FactoryGirl.build_stubbed(:custom_action)

    allow(action)
      .to receive(:actions)
      .and_return([alter_action1, alter_action2])

    action
  end
  let(:alter_action1) do
    action = double('custom actions action 1')

    allow(action)
      .to receive(:apply)
      .with(work_package)

    action
  end
  let(:alter_action2) do
    action = double('custom actions action 2')

    allow(action)
      .to receive(:apply)
      .with(work_package)

    action
  end
  let(:user) { FactoryGirl.build_stubbed(:user) }
  let(:instance) { described_class.new(action: custom_action, user: user) }
  let!(:update_wp_service) do
    wp_service_instance = double('WorkPackages::UpdateService instance')

    allow(WorkPackages::UpdateService)
      .to receive(:new)
      .with(user: user, work_package: work_package)
      .and_return(wp_service_instance)

    allow(wp_service_instance)
      .to receive(:call)
      .and_return(result)

    wp_service_instance
  end
  let(:work_package) { FactoryGirl.build_stubbed(:stubbed_work_package) }
  let(:result) do
    ServiceResult.new(result: work_package, success: true)
  end

  describe '#call' do
    let(:call) do
      instance.call(work_package: work_package)
    end

    it 'returns the update wp service result' do
      expect(call)
        .to eql result
    end

    it 'yields the result' do
      yielded = false

      proc = Proc.new do |call|
        yielded = call
      end

      instance.call(work_package: work_package, &proc)

      expect(yielded)
        .to be_success
    end

    it 'calls each registered action with the work package' do
      [alter_action1, alter_action2].each do |alter_action|
        expect(alter_action)
          .to receive(:apply)
          .with(work_package)
      end

      call
    end
  end
end
