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

describe WorkPackages::MoveService, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:work_package) do
    FactoryBot.build_stubbed(:stubbed_work_package)
  end
  let(:type) { FactoryBot.build_stubbed(:type) }
  let(:project) { FactoryBot.build_stubbed(:project) }

  let(:instance) { described_class.new(work_package, user) }
  let(:child_service_result_work_package) { work_package }
  let(:child_service_result) do
    ServiceResult.new success: true,
                      result: child_service_result_work_package
  end

  context 'when copying' do
    let(:expected_attributes) { { project: project } }
    let(:child_service_result_work_package) { FactoryBot.build_stubbed(:stubbed_work_package) }

    before do
      copy_double = double('copy service double')

      expect(WorkPackages::CopyService)
        .to receive(:new)
        .with(user: user,
              work_package: work_package)
        .and_return(copy_double)

      expect(copy_double)
        .to receive(:call)
        .with(expected_attributes)
        .and_return(child_service_result)

      allow(work_package)
        .to receive_message_chain(:self_and_descendants, :order_by_ancestors)
        .and_return [work_package]
    end

    it 'calls the copy service and merges its result' do
      expect(instance.call(project, nil, copy: true).result)
        .to eql child_service_result.result
    end

    context 'when providing a type and attributes' do
      let(:expected_attributes) do
        { project: project,
          type: type,
          subject: 'blubs' }
      end

      it 'calls the copy service and merges its result' do
        expect(instance.call(project, type, attributes: { subject: 'blubs' }, copy: true).result)
          .to eql child_service_result.result
      end
    end

    context 'for a parent' do
      let(:child_work_package) do
        FactoryBot.build_stubbed(:stubbed_work_package, parent: work_package)
      end
      let(:copied_child_work_package) do
        FactoryBot.build_stubbed(:stubbed_work_package)
      end
      let(:child_child_service_result) do
        ServiceResult.new success: true,
                          result: copied_child_work_package
      end

      let(:expected_child_attributes) { { project: project, parent_id: child_service_result_work_package.id } }

      before do
        copy_double = double('copy child service double')

        expect(WorkPackages::CopyService)
          .to receive(:new)
          .with(user: user,
                work_package: child_work_package)
          .and_return(copy_double)

        expect(copy_double)
          .to receive(:call)
          .with(expected_child_attributes)
          .and_return(child_child_service_result)

        allow(work_package)
          .to receive_message_chain(:descendants, :order_by_ancestors)
          .and_return [child_work_package]
      end

      it 'calls the copy service twice and merges its result' do
        call = instance.call(project, nil, copy: true)

        expect(call.result)
          .to eql child_service_result.result
        expect(call.dependent_results)
          .to match_array [child_child_service_result]
      end
    end
  end

  context 'when moving' do
    let(:expected_attributes) { { project: project } }

    before do
      update_double = double('update service double')

      expect(WorkPackages::UpdateService)
        .to receive(:new)
        .with(user: user,
              model: work_package)
        .and_return(update_double)

      expect(update_double)
        .to receive(:call)
        .with(expected_attributes)
        .and_return(child_service_result)
    end

    it 'calls the update service and returns its result' do
      expect(instance.call(project))
        .to eql child_service_result
    end

    context 'when providing a type and attributes' do
      let(:expected_attributes) do
        { project: project,
          type: type,
          subject: 'blubs' }
      end

      it 'calls the update service and returns its result' do
        expect(instance.call(project, type, attributes: { subject: 'blubs' }))
          .to eql child_service_result
      end
    end
  end
end
