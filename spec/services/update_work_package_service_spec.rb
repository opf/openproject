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

describe UpdateWorkPackageService, type: :model do
  let(:user) { FactoryGirl.build_stubbed(:user) }
  let(:project) do
    p = FactoryGirl.build_stubbed(:project)
    allow(p).to receive(:shared_versions).and_return([])

    p
  end
  let(:work_package) do
    wp = FactoryGirl.build_stubbed(:work_package, project: project)
    wp.type = FactoryGirl.build_stubbed(:type)
    wp.send(:clear_changes_information)

    wp
  end
  let(:instance) do
    UpdateWorkPackageService.new(user: user,
                                 work_package: work_package)
  end

  describe 'call' do
    let(:set_attributes_service) do
      service = double("SetAttributesWorkPackageService",
                       new: set_attributes_service_instance)

      stub_const('SetAttributesWorkPackageService', service)

      service
    end
    let(:set_attributes_service_instance) do
      instance = double("SetAttributesWorkPackageServiceInstance")

      allow(instance)
        .to receive(:call) do |attributes|
        work_package.attributes = attributes

        set_service_results
      end

      instance
    end
    let(:errors) { double('errors') }
    let(:set_service_results) { double('result', success?: true, errors: errors) }
    let(:work_package_save_result) { true }

    before do
      set_attributes_service
    end

    let(:send_notifications) { true }

    before do
      expect(JournalManager)
        .to receive(:with_send_notifications)
        .with(send_notifications)
        .and_yield

      allow(work_package)
        .to receive(:save)
        .and_return work_package_save_result
    end

    shared_examples_for 'service call' do
      subject { instance.call(attributes: call_attributes, send_notifications: send_notifications) }

      it 'is successful' do
        expect(subject.success?).to be_truthy
      end

      it 'sets the value' do
        subject

        attributes.each do |attribute, key|
          expect(work_package.send(attribute)).to eql key
        end
      end

      it 'has no errors' do
        expect(subject.errors).to be_empty
      end

      context 'when setting the attributes is unsuccessful (invalid)' do
        let(:errors) { double('errors') }
        let(:set_service_results) { double('result', success?: false, errors: errors) }

        it 'is unsuccessful' do
          expect(subject.success?).to be_falsey
        end

        it 'does not persist the changes' do
          subject

          expect(work_package).to_not receive(:save)
        end

        it 'exposes the errors' do
          subject

          expect(subject.errors).to eql errors
        end
      end

      context 'when the saving is unsuccessful' do
        let(:work_package_save_result) { false }

        it 'is unsuccessful' do
          expect(subject.success?).to be_falsey
        end

        it 'leaves the value unchanged' do
          subject

          expect(work_package.changed?).to be_truthy
        end

        it "exposes the work_packages's errors" do
          saving_errors = double('saving_errors')
          allow(work_package)
            .to receive(:errors)
            .and_return(saving_errors)

          subject

          expect(subject.errors).to eql saving_errors
        end
      end
    end

    context 'update subject before calling the service' do
      let(:call_attributes) { {} }
      let(:attributes) { { subject: 'blubs blubs' } }

      before do
        work_package.attributes = attributes
      end

      it_behaves_like 'service call'
    end

    context 'updating subject via attributes' do
      let(:call_attributes) { attributes }
      let(:attributes) { { subject: 'blubs blubs' } }

      it_behaves_like 'service call'
    end

    context 'when switching the project' do
      let(:target_project) do
        FactoryGirl.build_stubbed(:project)
      end
      let(:call_attributes) { attributes }
      let(:attributes) { { project: target_project } }

      it_behaves_like 'service call'

      context 'relations' do
        it 'removes the relations if the setting does not permit cross project relations' do
          allow(Setting)
            .to receive(:cross_project_work_package_relations?)
            .and_return false
          expect(work_package)
            .to receive_message_chain(:relations_from, :clear)
          expect(work_package)
            .to receive_message_chain(:relations_to, :clear)

          instance.call(attributes: { project: target_project })
        end

        it 'leaves the relations unchanged if the setting allows cross project relations' do
          allow(Setting)
            .to receive(:cross_project_work_package_relations?)
            .and_return true
          expect(work_package)
            .to_not receive(:relations_from)
          expect(work_package)
            .to_not receive(:relations_to)

          instance.call(attributes: { project: target_project })
        end
      end

      context 'time_entries' do
        it 'moves the time entries' do
          expect(work_package)
            .to receive(:move_time_entries)
            .with(target_project)

          instance.call(attributes: { project: target_project })
        end
      end

      context 'when having children' do
        let(:child_work_package) do
          child_work_package = FactoryGirl.build_stubbed(:work_package,
                                                         parent: work_package,
                                                         project: project)

          allow(work_package)
            .to receive(:children)
            .and_return [child_work_package]

          child_work_package
        end

        let(:attributes) do
          { attributes: { project: target_project } }
        end

        let(:child_service) do
          double('UpdateChildWorkPackageChildService')
        end

        it 'calls the service again with the same attributes for each child' do
          expect(UpdateChildWorkPackageService)
            .to receive(:new)
            .with(user: user,
                  work_package: child_work_package)
            .and_return child_service

          expect(child_service)
            .to receive(:call)
            .with(attributes)
            .and_return true

          instance.call(attributes)
        end

        it 'returns errors of the child service calls and returns false' do
          expect(UpdateChildWorkPackageService)
            .to receive(:new)
            .with(user: user,
                  work_package: child_work_package)
            .and_return child_service

          errors = double('child service errors')

          expect(child_service)
            .to receive(:call)
            .with(attributes)
            .and_return [false, errors]

          result = instance.call(attributes)

          expect(result.success?).to be_falsey
          expect(result.errors).to eql errors
        end
      end
    end

    context 'when switching the type' do
      let(:target_type) { FactoryGirl.build_stubbed(:type) }

      context 'custom_values' do
        it 'resets the custom values' do
          expect(work_package)
            .to receive(:reset_custom_values!)

          instance.call(attributes: { type: target_type })
        end
      end
    end
  end
end
