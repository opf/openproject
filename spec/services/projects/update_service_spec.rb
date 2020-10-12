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

describe Projects::UpdateService, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:contract_class) do
    double('contract_class', '<=': true)
  end
  let(:project_valid) { true }
  let(:instance) do
    described_class.new(user: user,
                        model: project,
                        contract_class: contract_class)
  end
  let(:call_attributes) { { name: 'Some name', identifier: 'Some identifier' } }
  let(:set_attributes_success) do
    true
  end
  let(:set_attributes_errors) do
    double('set_attributes_errors')
  end
  let(:set_attributes_result) do
    ServiceResult.new result: project,
                      success: set_attributes_success,
                      errors: set_attributes_errors
  end
  let!(:project) do
    FactoryBot.build_stubbed(:project, status: project_status).tap do |p|
      allow(p)
        .to receive(:save)
        .and_return(project_valid)

      project_status.clear_changes_information
    end
  end
  let(:project_status) do
    FactoryBot.build_stubbed(:project_status)
  end
  let!(:set_attributes_service) do
    service = double('set_attributes_service_instance')

    allow(Projects::SetAttributesService)
      .to receive(:new)
      .with(user: user,
            model: project,
            contract_class: contract_class,
            contract_options: {})
      .and_return(service)

    allow(service)
      .to receive(:call)
      .and_return(set_attributes_result)
  end

  describe 'call' do
    subject { instance.call(call_attributes) }

    it 'is successful' do
      expect(subject.success?).to be_truthy
    end

    it 'returns the result of the SetAttributesService' do
      expect(subject)
        .to eql set_attributes_result
    end

    it 'persists the project' do
      expect(project)
        .to receive(:save)
        .and_return(project_valid)

      subject
    end

    it 'returns the project' do
      expect(subject.result)
        .to eql project
    end

    it 'sends an update notification' do
      expect(OpenProject::Notifications)
        .to receive(:send)
        .with('project_updated', project: project)

      subject
    end

    context 'if the identifier is altered' do
      let(:call_attributes) { { identifier: 'Some identifier' } }

      before do
        allow(project)
          .to receive(:changes)
          .and_return('identifier' => %w(lorem ipsum))
      end

      it 'sends the notification' do
        expect(OpenProject::Notifications)
          .to receive(:send)
          .with('project_updated', project: project)
        expect(OpenProject::Notifications)
          .to receive(:send)
          .with('project_renamed', project: project)

        subject
      end
    end

    context 'if the parent is altered' do
      before do
        allow(project)
          .to receive(:changes)
          .and_return('parent_id' => [nil, 5])
      end

      it 'updates the versions associated with the work packages' do
        expect(WorkPackage)
          .to receive(:update_versions_from_hierarchy_change)
          .with(project)

        subject
      end
    end

    context 'if the project status is altered' do
      before do
        allow(project_status)
          .to receive(:changed?)
          .and_return(true)
      end

      it 'persists the changes' do
        expect(project_status)
          .to receive(:save)

        subject
      end
    end

    context 'if the SetAttributeService is unsuccessful' do
      let(:set_attributes_success) { false }

      it 'is unsuccessful' do
        expect(subject.success?).to be_falsey
      end

      it 'returns the result of the SetAttributesService' do
        expect(subject)
          .to eql set_attributes_result
      end

      it 'does not persist the changes' do
        expect(project)
          .to_not receive(:save)

        subject
      end

      it "exposes the contract's errors" do
        subject

        expect(subject.errors).to eql set_attributes_errors
      end
    end

    context 'if the project is invalid' do
      let(:project_valid) { false }

      it 'is unsuccessful' do
        expect(subject.success?).to be_falsey
      end

      it "exposes the project's errors" do
        subject

        expect(subject.errors).to eql project.errors
      end
    end
  end
end
