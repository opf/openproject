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

require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe Meeting do
  shared_let (:user1) { create(:user) }
  shared_let (:user2) { create(:user) }
  let(:project) { create(:project, members: project_members) }
  let(:meeting) { create(:meeting, project:, author: user1) }
  let(:agenda) do
    meeting.create_agenda text: "Meeting Agenda text"
    meeting.reload_agenda # avoiding stale object errors
  end
  let(:project_members) { {} }

  let(:role) { create(:project_role, permissions: [:view_meetings]) }

  it { is_expected.to belong_to :project }
  it { is_expected.to belong_to :author }
  it { is_expected.to validate_presence_of :title }

  describe "new instance" do
    let(:meeting) { build(:meeting, project:, title: "dingens") }

    describe "to_s" do
      it { expect(meeting.to_s).to eq("dingens") }
    end

    describe "start_date" do
      it { expect(meeting.start_date).to eq(Date.tomorrow.iso8601) }
    end

    describe "start_month" do
      it { expect(meeting.start_month).to eq(Date.tomorrow.month) }
    end

    describe "start_year" do
      it { expect(meeting.start_year).to eq(Date.tomorrow.year) }
    end

    describe "end_time" do
      it { expect(meeting.end_time).to eq(Date.tomorrow + 11.hours) }
    end

    describe "date validations" do
      it "marks invalid start dates" do
        meeting.start_date = "-"
        expect(meeting.start_date).to eq("-")
        expect(meeting.start_time).to be_nil
        expect(meeting).not_to be_valid
        expect(meeting.errors.count).to eq(1)
      end

      it "marks invalid start hours" do
        meeting.start_time_hour = "-"
        expect(meeting.start_time_hour).to eq("-")
        expect(meeting.start_time).to be_nil
        expect(meeting).not_to be_valid
        expect(meeting.errors.count).to eq(1)
      end

      it "is not invalid when setting date_time explicitly" do
        meeting.start_time = DateTime.now
        expect(meeting).to be_valid
      end

      it "raises an error trying to set invalid time" do
        expect { meeting.start_time = "-" }.to raise_error(Date::Error)
      end

      it "accepts changes after invalid dates" do
        meeting.start_date = "-"
        expect(meeting.start_time).to be_nil
        expect(meeting).not_to be_valid
        expect(meeting.errors[:start_date]).to contain_exactly "is not a valid date. Required format: YYYY-MM-DD."

        meeting.start_date = Time.zone.today.iso8601
        expect(meeting).to be_valid

        meeting.save!
        expect(meeting.start_time).to eq(Time.zone.today + 10.hours)
      end
    end
  end

  describe "all_changeable_participants" do
    describe "WITH a user having the view_meetings permission" do
      let(:project_members) { { user1 => role } }

      it "contains the user" do
        expect(meeting.all_changeable_participants).to eq([user1])
      end
    end

    describe "WITH a user not having the view_meetings permission" do
      let(:role2) { create(:project_role, permissions: []) }
      let(:project_members) { { user1 => role, user2 => role2 } }

      it "does not contain the user" do
        expect(meeting.all_changeable_participants).not_to include(user2)
      end
    end

    describe "WITH a user being locked but invited" do
      let(:locked_user) { create(:locked_user) }

      before do
        meeting.participants_attributes = [{ user_id: locked_user.id, invited: 1 }]
      end

      it "contains the user" do
        expect(meeting.all_changeable_participants).to include(locked_user)
      end
    end
  end

  describe "participants and author as watchers" do
    let(:project_members) { { user1 => role, user2 => role } }

    before do
      meeting.participants.build(user: user2)
      meeting.save!
    end

    it { expect(meeting.watchers.collect(&:user)).to contain_exactly(user1, user2) }
  end

  describe "#close_agenda_and_copy_to_minutes" do
    before do
      agenda # creating it

      meeting.close_agenda_and_copy_to_minutes!
    end

    it "creates a meeting with the agenda's text" do
      expect(meeting.minutes.text).to eq(meeting.agenda.text)
    end

    it "closes the agenda" do
      expect(meeting.agenda).to be_locked
    end
  end

  describe "Timezones" do
    shared_examples "uses that zone" do |zone|
      it do
        meeting.start_date = "2016-07-01"
        expect(meeting.start_time.zone).to eq(zone)
      end
    end

    context "default zone" do
      it_behaves_like "uses that zone", "UTC"
    end

    context "other timezone set" do
      let!(:old_time_zone) { Time.zone }

      before do
        Time.zone = "EST"
      end

      after do
        Time.zone = old_time_zone.name
      end

      it_behaves_like "uses that zone", "EST"
    end
  end

  describe "acts_as_watchable" do
    it "is watchable" do
      expect(described_class).to include(OpenProject::Acts::Watchable::InstanceMethods)
    end

    it "uses the :view_meetings permission" do
      expect(described_class.acts_as_watchable_permission).to eq(:view_meetings)
    end

    it "uses the :view_meetings permission in STI classes" do
      expect(StructuredMeeting.acts_as_watchable_permission).to eq(:view_meetings)
    end
  end
end
