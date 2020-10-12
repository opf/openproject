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

describe WorkPackages::DeleteService do
  let(:user) do
    FactoryBot.build_stubbed(:user)
  end
  let(:work_package) do
    FactoryBot.build_stubbed(:work_package, type: FactoryBot.build_stubbed(:type))
  end
  let(:instance) do
    described_class
      .new(user: user,
           model: work_package)
  end
  let(:destroyed_result) { true }
  let(:destroy_allowed) { true }
  subject { instance.call }

  before do
    expect(work_package)
      .to receive(:destroy)
      .and_return(destroyed_result)

    allow(work_package)
      .to receive(:destroyed?)
      .and_return(destroyed_result)

    allow(user)
      .to receive(:allowed_to?)
      .with(:delete_work_packages, work_package.project)
      .and_return(destroy_allowed)
  end

  it 'destroys the work package' do
    subject
  end

  it 'is successful' do
    expect(subject)
      .to be_success
  end

  it 'returns the destroyed work package' do
    expect(subject.result)
      .to eql work_package
  end

  it 'returns an empty errors array' do
    expect(subject.errors)
      .to be_empty
  end

  context 'when the work package could not be destroyed' do
    let(:destroyed_result) { false }

    it 'it is no success' do
      expect(subject)
        .not_to be_success
    end
  end

  context 'with ancestors' do
    let(:parent) do
      FactoryBot.build_stubbed(:work_package)
    end
    let(:grandparent) do
      FactoryBot.build_stubbed(:work_package)
    end
    let(:expect_inherited_attributes_service_calls) do
      inherited_service_instance = double(WorkPackages::UpdateAncestorsService)

      service_result = ServiceResult.new(success: true,
                                         result: work_package)

      service_result.dependent_results += [ServiceResult.new(success: true,
                                                             result: parent),
                                           ServiceResult.new(success: true,
                                                             result: grandparent)]

      expect(WorkPackages::UpdateAncestorsService)
        .to receive(:new)
        .with(user: user,
              work_package: work_package)
        .and_return(inherited_service_instance)

      expect(inherited_service_instance)
        .to receive(:call)
        .with(work_package.attributes.keys.map(&:to_sym))
        .and_return(service_result)
    end
    let(:expect_no_inherited_attributes_service_calls) do
      expect(WorkPackages::UpdateAncestorsService)
        .not_to receive(:new)
    end

    it 'calls the inherit attributes service for each ancestor' do
      expect_inherited_attributes_service_calls

      subject
    end

    context 'when the work package could not be destroyed' do
      let(:destroyed_result) { false }

      it 'does not call inherited attributes service' do
        expect_no_inherited_attributes_service_calls

        subject
      end
    end
  end

  context 'with descendants' do
    let(:child) do
      FactoryBot.build_stubbed(:work_package)
    end
    let(:grandchild) do
      FactoryBot.build_stubbed(:work_package)
    end
    let(:descendants) do
      [child, grandchild]
    end

    before do
      allow(work_package)
        .to receive(:descendants)
        .and_return(descendants)

      descendants.each do |descendant|
        allow(descendant)
          .to receive(:destroy)
      end
    end

    it 'destroys the descendants' do
      descendants.each do |descendant|
        expect(descendant)
          .to receive(:destroy)
      end

      subject
    end

    it 'returns the descendants as part of the result' do
      subject

      expect(subject.all_results)
        .to match_array [work_package] + descendants
    end

    context 'if the work package could not be destroyed' do
      let(:destroyed_result) { false }

      it 'does not destroy the descendants' do
        descendants.each do |descendant|
          expect(descendant)
            .not_to receive(:destroy)
        end

        subject
      end
    end
  end
end
