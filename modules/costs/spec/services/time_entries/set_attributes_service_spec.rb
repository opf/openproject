# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe TimeEntries::SetAttributesService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:activity) { build_stubbed(:time_entry_activity, project:) }
  let!(:default_activity) { build_stubbed(:time_entry_activity, project:, is_default: true) }
  let(:work_package) { build_stubbed(:work_package) }
  let(:project) { build_stubbed(:project) }
  let(:spent_on) { Time.zone.today.to_s }
  let(:hours) { 5.0 }
  let(:comments) { "some comment" }
  let(:contract_instance) do
    double("contract_instance").tap do |contract| # rubocop:disable RSpec/VerifiedDoubles
      allow(contract).to receive_messages(
        validate: contract_valid,
        errors: contract_errors
      )
    end
  end

  let(:contract_errors) { double("contract_errors") } # rubocop:disable RSpec/VerifiedDoubles
  let(:contract_valid) { true }
  let(:time_entry_valid) { true }

  let(:instance) do
    described_class.new(user:,
                        model: time_entry_instance,
                        contract_class:)
  end
  let(:time_entry_instance) { TimeEntry.new }
  let(:contract_class) do
    allow(TimeEntries::CreateContract)
      .to receive(:new)
      .with(anything, user, options: {})
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

  it "creates a new time entry" do
    expect(subject.result)
      .to eql time_entry_instance
  end

  it "is a success" do
    expect(subject)
      .to be_success
  end

  it "has the service's user assigned" do
    subject

    expect(time_entry_instance.user)
      .to eql user
  end

  it "notes the user to be system changed" do
    subject

    expect(time_entry_instance.changed_by_system["user_id"])
      .to eql [nil, user.id]
  end

  context "with params" do
    let(:params) do
      {
        entity: work_package,
        project:,
        activity:,
        spent_on:,
        comments:,
        hours:
      }
    end

    let(:expected) do
      {
        user_id: user.id,
        entity_type: "WorkPackage",
        entity_id: work_package.id,
        project_id: project.id,
        activity_id: activity.id,
        spent_on: Date.parse(spent_on),
        comments:,
        hours:
      }.with_indifferent_access
    end

    it "assigns the params" do
      subject

      attributes_of_interest = time_entry_instance
                                 .attributes
                                 .slice(*expected.keys)

      expect(attributes_of_interest)
        .to eql(expected)
    end

    context "with an existing record and params including an empty user" do
      let(:params) do
        {
          user_id: ""
        }
      end

      before do
        allow(time_entry_instance).to receive(:new_record?).and_return(false)
      end

      it "runs correctly and not raise an error trying to assign the timezone (Reggression #63843)" do
        expect do
          subject
        end.not_to raise_error

        expect(time_entry_instance.user).to be_nil
      end
    end
  end

  context "with a user with a defined timezone" do
    it "extracts the current timezone from the user and stores it in the time entry" do
      user.pref[:time_zone] = "America/Los_Angeles"
      subject

      expect(time_entry_instance.time_zone).to eq "America/Los_Angeles"
    end
  end

  context "with an ongoing time entry" do
    let(:params) do
      {
        spent_on: Time.zone.today,
        ongoing: true,
        user_id: user.id,
        entity_type: "WorkPackage",
        entity_id: work_package.id,
        activity_id: activity.id
      }
    end

    before do
      user.pref[:time_zone] = "America/Los_Angeles"
    end

    context "when start_time is allowed" do
      before do
        allow(TimeEntry).to receive(:can_track_start_and_end_time?).and_return(true)
      end

      it "sets the start_time to the users current time" do
        Timecop.freeze do
          subject

          current_time = ActiveSupport::TimeZone[user.time_zone].now

          expect(time_entry_instance.start_time).to eq((current_time.hour * 60) + current_time.min)
        end
      end
    end

    context "when start_time is not allowed" do
      before do
        allow(TimeEntry).to receive(:can_track_start_and_end_time?).and_return(false)
      end

      it "does not set the start_time" do
        subject
        expect(time_entry_instance.start_time).to be_nil
      end
    end
  end

  context "with hours == 0" do
    let(:params) do
      {
        hours: 0
      }
    end

    it "sets hours to nil" do
      subject

      expect(time_entry_instance.hours)
        .to be_nil
    end
  end

  context "with project not specified" do
    let(:params) do
      {
        entity: work_package
      }
    end

    it "sets the project to the entity's project" do
      subject

      expect(time_entry_instance.project)
        .to eql(work_package.project)
    end
  end

  context "with another user setting logged by" do
    let(:other_user) { create(:user) }
    let(:time_entry_instance) { create(:time_entry, user: other_user, logged_by: other_user, hours: 1) }

    let(:params) do
      {
        hours: 1234
      }
    end

    it "updates the entry, and updates the logged by" do
      expect { subject }
        .to change(time_entry_instance, :hours).from(1).to(1234)
        .and change(time_entry_instance, :logged_by).from(other_user).to(user)

      expect(time_entry_instance.user).to eq other_user
    end
  end

  context "with an invalid contract" do
    let(:contract_valid) { false }
    let(:expect_time_instance_save) do
      expect(time_entry_instance).not_to receive(:save) # rubocop:disable RSpec/MessageSpies
    end

    it "returns failure" do
      expect(subject)
        .not_to be_success
    end

    it "returns the contract's errors" do
      expect(subject.errors)
        .to eql(contract_errors)
    end
  end
end
