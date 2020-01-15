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

describe TimeEntries::SetAttributesService, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:activity) { FactoryBot.build_stubbed(:time_entry_activity, project: project) }
  let!(:default_activity) { FactoryBot.build_stubbed(:time_entry_activity, project: project, is_default: true) }
  let(:work_package) { FactoryBot.build_stubbed(:work_package) }
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:spent_on) { Date.today.to_s }
  let(:hours) { 5.0 }
  let(:comments) { 'some comment' }
  let(:contract_instance) do
    contract = double('contract_instance')
    allow(contract)
      .to receive(:validate)
      .and_return(contract_valid)
    allow(contract)
      .to receive(:errors)
      .and_return(contract_errors)
    contract
  end

  let(:contract_errors) { double('contract_errors') }
  let(:contract_valid) { true }
  let(:time_entry_valid) { true }

  let(:instance) do
    described_class.new(user: user,
                        model: time_entry_instance,
                        contract_class: contract_class)
  end
  let(:time_entry_instance) { TimeEntry.new }
  let(:contract_class) do
    allow(TimeEntries::CreateContract)
      .to receive(:new)
      .with(anything, user, options: { changed_by_system: ["user_id"] })
      .and_return(contract_instance)

    TimeEntries::CreateContract
  end

  let(:params) { {} }

  before do
    allow(time_entry_instance)
      .to receive(:valid?)
      .and_return(time_entry_valid)
  end

  subject { instance.call(params) }

  it 'creates a new time entry' do
    expect(subject.result)
      .to eql time_entry_instance
  end

  it 'is a success' do
    is_expected
      .to be_success
  end

  it "has the service's user assigned" do
    subject

    expect(time_entry_instance.user)
      .to eql user
  end

  it 'notes the user to be system changed' do
    subject

    expect(instance.changed_by_system)
      .to include('user_id')
  end

  it 'assigns the default TimeEntryActivity' do
    allow(TimeEntryActivity)
      .to receive(:default)
      .and_return(default_activity)

    subject

    expect(time_entry_instance.activity)
      .to eql default_activity
  end

  context 'with params' do
    let(:params) do
      {
        work_package: work_package,
        project: project,
        activity: activity,
        spent_on: spent_on,
        comments: comments,
        hours: hours
      }
    end

    let(:expected) do
      {
        user_id: user.id,
        work_package_id: work_package.id,
        project_id: project.id,
        activity_id: activity.id,
        spent_on: Date.parse(spent_on),
        comments: comments,
        hours: hours
      }.with_indifferent_access
    end

    it 'assigns the params' do
      subject

      attributes_of_interest = time_entry_instance
                                 .attributes
                                 .slice(*expected.keys)

      expect(attributes_of_interest)
        .to eql(expected)
    end
  end

  context 'with hours == 0' do
    let(:params) do
      {
        hours: 0
      }
    end

    it 'sets hours to nil' do
      subject

      expect(time_entry_instance.hours)
        .to be_nil
    end
  end

  context 'with project not specified' do
    let(:params) do
      {
        work_package: work_package
      }
    end

    it 'sets the project to the work_package\'s project' do
      subject

      expect(time_entry_instance.project)
        .to eql(work_package.project)
    end
  end

  context 'with an invalid contract' do
    let(:contract_valid) { false }
    let(:expect_time_instance_save) do
      expect(time_entry_instance)
        .not_to receive(:save)
    end

    it 'returns failure' do
      is_expected
        .not_to be_success
    end

    it "returns the contract's errors" do
      expect(subject.errors)
        .to eql(contract_errors)
    end
  end
end
