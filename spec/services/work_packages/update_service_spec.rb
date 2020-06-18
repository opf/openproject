#-- encoding: UTF-8

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

describe WorkPackages::UpdateService, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:project) do
    p = FactoryBot.build_stubbed(:project)
    allow(p).to receive(:shared_versions).and_return([])

    p
  end
  let(:work_package) do
    wp = FactoryBot.build_stubbed(:work_package, project: project)
    wp.type = FactoryBot.build_stubbed(:type)
    wp.send(:clear_changes_information)

    wp
  end
  let(:instance) do
    described_class.new(user: user,
                        model: work_package)
  end

  before do
    # Stub update_ancestors because it messes with the jouralizing expectations
    allow(instance).to receive(:update_ancestors).and_return []
  end

  describe 'call' do
    let(:set_attributes_service) do
      service = double("WorkPackages::SetAttributesService",
                       new: set_attributes_service_instance)

      stub_const('WorkPackages::SetAttributesService', service)

      service
    end
    let(:set_attributes_service_instance) do
      instance = double("WorkPackages::SetAttributesServiceInstance")

      allow(instance)
        .to receive(:call) do |attributes|
        work_package.attributes = attributes

        set_service_results
      end

      instance
    end
    let(:errors) { [] }
    let(:set_service_results) { ServiceResult.new success: true, result: work_package }
    let(:work_package_save_result) { true }

    before do
      set_attributes_service
    end

    let(:send_notifications) { true }

    before do
      expect(Journal::NotificationConfiguration)
        .to receive(:with)
        .with(send_notifications)
        .and_yield

      allow(work_package)
        .to receive(:save)
        .and_return work_package_save_result
    end

    shared_examples_for 'service call' do
      subject { instance.call(call_attributes.merge(send_notifications: send_notifications).symbolize_keys) }

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
        expect(subject.errors.all?(&:empty?)).to be_truthy
      end

      context 'when setting the attributes is unsuccessful (invalid)' do
        let(:errors) { double('set errors', empty?: false) }
        let(:set_service_results) { ServiceResult.new success: false, errors: errors, result: work_package }

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
        let(:saving_errors) { double('saving_errors', empty?: false) }

        before do
          allow(work_package)
            .to receive(:errors)
            .and_return(saving_errors)
        end

        it 'is unsuccessful' do
          expect(subject.success?).to be_falsey
        end

        it 'leaves the value unchanged' do
          subject

          expect(work_package.changed?).to be_truthy
        end

        it "exposes the work_packages's errors" do
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
        FactoryBot.build_stubbed(:project)
      end
      let(:call_attributes) { attributes }
      let(:attributes) { { project: target_project } }

      it_behaves_like 'service call'

      context 'relations' do
        it 'removes the relations if the setting does not permit cross project relations' do
          allow(Setting)
            .to receive(:cross_project_work_package_relations?)
            .and_return false
          relations = double('relations')
          expect(Relation)
            .to receive(:non_hierarchy_of_work_package)
            .with([work_package])
            .and_return(relations)
          expect(relations)
            .to receive(:destroy_all)

          instance.call(project: target_project)
        end

        it 'leaves the relations unchanged if the setting allows cross project relations' do
          allow(Setting)
            .to receive(:cross_project_work_package_relations?)
            .and_return true
          expect(work_package)
            .to_not receive(:relations_from)
          expect(work_package)
            .to_not receive(:relations_to)

          instance.call(project: target_project)
        end
      end

      context 'time_entries' do
        it 'moves the time entries' do
          scope = double('scope')

          expect(TimeEntry)
            .to receive(:on_work_packages)
            .with([work_package])
            .and_return(scope)

          expect(scope)
            .to receive(:update_all)
            .with(project_id: target_project.id)

          instance.call(project: target_project)
        end
      end
    end

    context 'when switching the type' do
      let(:target_type) { FactoryBot.build_stubbed(:type) }

      context 'custom_values' do
        it 'resets the custom values' do
          expect(work_package)
            .to receive(:reset_custom_values!)

          instance.call(type: target_type)
        end
      end
    end
  end
end
