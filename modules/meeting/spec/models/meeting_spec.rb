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

require File.dirname(__FILE__) + '/../spec_helper'

describe Meeting, type: :model do
  it { is_expected.to belong_to :project }
  it { is_expected.to belong_to :author }
  it { is_expected.to validate_presence_of :title }

  let(:project) { FactoryBot.create(:project) }
  let(:user1) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:meeting) { FactoryBot.create(:meeting, project: project, author: user1) }
  let(:agenda) do
    meeting.create_agenda text: 'Meeting Agenda text'
    meeting.reload_agenda # avoiding stale object errors
  end

  let(:role) { FactoryBot.create(:role, permissions: [:view_meetings]) }

  before do
    @m = FactoryBot.build :meeting, title: 'dingens'
  end

  describe 'to_s' do
    it { expect(@m.to_s).to eq('dingens') }
  end

  describe 'start_date' do
    it { expect(@m.start_date).to eq(Date.tomorrow.iso8601) }
  end

  describe 'start_month' do
    it { expect(@m.start_month).to eq(Date.tomorrow.month) }
  end

  describe 'start_year' do
    it { expect(@m.start_year).to eq(Date.tomorrow.year) }
  end

  describe 'end_time' do
    it { expect(@m.end_time).to eq(Date.tomorrow + 11.hours) }
  end

  describe 'date validations' do
    it 'marks invalid start dates' do
      @m.start_date = '-'
      expect(@m.start_date).to eq('-')
      expect { @m.start_time }.to raise_error(ArgumentError)
      expect(@m).not_to be_valid
      expect(@m.errors.count).to eq(1)
    end

    it 'marks invalid start hours' do
      @m.start_time_hour = '-'
      expect(@m.start_time_hour).to eq('-')
      expect { @m.start_time }.to raise_error(ArgumentError)
      expect(@m).not_to be_valid
      expect(@m.errors.count).to eq(1)
    end

    it 'is not invalid when setting date_time explicitly' do
      @m.start_time = DateTime.now
      expect(@m).to be_valid
    end

    it 'is invalid when setting date_time wrong' do
      @m.start_time = '-'
      expect(@m).not_to be_valid
    end

    it 'accepts changes after invalid dates' do
      @m.start_date = '-'
      expect { @m.start_time }.to raise_error(ArgumentError)
      expect(@m).not_to be_valid

      @m.start_date = Date.today.iso8601
      expect(@m).to be_valid

      @m.save!
      expect(@m.start_time).to eq(Date.today + 10.hours)
    end
  end

  describe 'all_changeable_participants' do
    describe 'WITH a user having the view_meetings permission' do
      before do
        project.add_member user1, [role]
        project.save!
      end

      it 'should contain the user' do
        expect(meeting.all_changeable_participants).to eq([user1])
      end
    end

    describe 'WITH a user not having the view_meetings permission' do
      let(:role2) { FactoryBot.create(:role, permissions: []) }

      before do
        # adding both users so that the author is valid
        project.add_member user1, [role]
        project.add_member user2, [role2]

        project.save!
      end

      it 'should not contain the user' do
        expect(meeting.all_changeable_participants.include?(user2)).to be_falsey
      end
    end

    describe 'WITH a user being locked but invited' do
      let(:locked_user) { FactoryBot.create(:locked_user) }
      before do
        meeting.participants_attributes = [{ 'user_id' => locked_user.id, 'invited' => 1 }]
      end

      it 'should contain the user' do
        expect(meeting.all_changeable_participants.include?(locked_user)).to be_truthy
      end
    end
  end

  describe 'participants and author as watchers' do
    before do
      project.add_member user1, [role]
      project.add_member user2, [role]

      project.save!

      meeting.participants.build(user: user2)
      meeting.save!
    end

    it { expect(meeting.watchers.collect(&:user)).to match_array([user1, user2]) }
  end

  describe '#close_agenda_and_copy_to_minutes' do
    before do
      agenda # creating it

      meeting.close_agenda_and_copy_to_minutes!
    end

    it "should create a meeting with the agenda's text" do
      expect(meeting.minutes.text).to eq(meeting.agenda.text)
    end

    it 'should close the agenda' do
      expect(meeting.agenda.locked?).to be_truthy
    end
  end

  describe 'Timezones' do
    shared_examples 'uses that zone' do |zone|
      it do
        @m.start_date = '2016-07-01'
        expect(@m.start_time.zone).to eq(zone)
      end
    end

    context 'default zone' do
      it_behaves_like 'uses that zone', 'UTC'
    end

    context 'other timezone set' do
      let!(:old_time_zone) { Time.zone }

      before do
        Time.zone = 'EST'
      end

      after do
        Time.zone = old_time_zone.name
      end

      it_behaves_like 'uses that zone', 'EST'
    end
  end

  describe 'Copied meetings' do
    before do
      project.add_member user1, [role]
      project.add_member user2, [role]

      project.save!

      meeting.start_date = '2013-03-27'
      meeting.start_time_hour = '15:35'
      meeting.participants.build(user: user2)
      meeting.save!
    end

    it 'should have the same start_time as the original meeting' do
      copy = meeting.copy({})
      expect(copy.start_time).to eq(meeting.start_time)
    end

    it 'should delete the copied meeting author if no author is given as parameter' do
      copy = meeting.copy({})
      expect(copy.author).to be_nil
    end

    it 'should set the author to the provided author if one is given' do
      copy = meeting.copy author: user2
      expect(copy.author).to eq(user2)
    end

    it 'should clear participant ids and attended flags for all copied attendees' do
      copy = meeting.copy({})
      expect(copy.participants.all? { |p| p.id.nil? && !p.attended }).to be_truthy
    end
  end
end
