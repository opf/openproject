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

RSpec.describe CustomActions::UpdateWorkPackageService do
  let(:custom_action) do
    action = build_stubbed(:custom_action)

    allow(action)
      .to receive(:actions)
      .and_return([alter_action1, alter_action2])

    action
  end
  let(:alter_action1) do
    action = double("custom actions action 1", key: "abc", priority: 100)

    allow(action)
      .to receive(:apply)
      .with(work_package) do
      work_package.subject = ""
    end

    action
  end
  let(:alter_action2) do
    action = double("custom actions action 2", key: "def", priority: 10)

    allow(action)
      .to receive(:apply)
      .with(work_package) do
      work_package.status_id = 100
    end

    action
  end
  let(:user) { build_stubbed(:user) }
  let(:instance) { described_class.new(action: custom_action, user:) }
  let(:update_service_call_implementation) do
    -> do
      result
    end
  end
  let!(:update_wp_service) do
    wp_service_instance = instance_double(WorkPackages::UpdateService)

    allow(WorkPackages::UpdateService)
      .to receive(:new)
      .with(user:, model: work_package)
      .and_return(wp_service_instance)

    allow(wp_service_instance)
      .to receive(:call) do
      update_service_call_implementation.()
    end

    wp_service_instance
  end
  let(:work_package) { build_stubbed(:work_package) }
  let(:result) do
    ServiceResult.success(result: work_package)
  end
  let(:validation_result) { true }
  let!(:contract) do
    contract = double("contract")

    allow(WorkPackages::UpdateContract)
      .to receive(:new)
      .with(work_package, user, options: {})
      .and_return(contract)

    allow(contract)
      .to receive(:validate)
      .and_return(validation_result)

    contract
  end

  describe "#call" do
    let(:call) do
      instance.call(work_package:)
    end
    let(:subject) { call }

    it "returns the update wp service result" do
      expect(call)
        .to eql result
    end

    it "yields the result" do
      yielded = false

      proc = Proc.new do |call|
        yielded = call
      end

      instance.call(work_package:, &proc)

      expect(yielded)
        .to be_success
    end

    it "calls each registered action with the work package" do
      [alter_action1, alter_action2].each do |alter_action|
        expect(alter_action)
          .to receive(:apply)
          .with(work_package)
      end

      call
    end

    it "calls the registered actions based on their priority" do
      call_order = []

      [alter_action1, alter_action2].each do |alter_action|
        allow(alter_action)
          .to receive(:apply)
          .with(work_package) do
          call_order << alter_action
        end
      end

      call

      expect(call_order)
        .to eql [alter_action2, alter_action1]
    end

    context "on validation error" do
      before do
        allow(contract)
          .to receive(:validate) do
          work_package.subject.present?
        end

        allow(contract)
          .to receive(:errors)
          .and_return(instance_double(ActiveModel::Errors, attribute_names: [alter_action1.key]))

        work_package.lock_version = 200

        subject
      end

      let(:update_service_call_implementation) do
        -> do
          # check that the work package retains only the valid changes
          # when passing it to the update service
          expect(work_package.subject)
            .not_to eql ""

          expect(work_package.status_id)
            .to be 100

          expect(work_package.lock_version)
            .to be 200

          result
        end
      end

      it "is successful" do
        expect(subject)
          .to be_success
      end
    end

    context "on unfixable validation error" do
      let(:result) do
        ServiceResult.failure(result: work_package)
      end
      let(:update_service_call_implementation) do
        -> do
          # check that the work package has all the changes
          # of the actions when passing it to the update service
          expect(work_package.subject)
            .to be_blank

          expect(work_package.status_id)
            .to be 100

          expect(work_package.lock_version)
            .to be 200

          result
        end
      end

      before do
        allow(contract)
          .to receive(:validate)
          .and_return(false)

        allow(contract)
          .to receive(:errors)
          .and_return(instance_double(ActiveModel::Errors, attribute_names: [:base]))

        work_package.lock_version = 200

        subject
      end

      it "is failure" do
        expect(subject)
          .to be_failure
      end
    end
  end
end
