#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe Meeting, :type => :model do
  it {is_expected.to belong_to :project}
  it {is_expected.to belong_to :author}
  it {is_expected.to validate_presence_of :title}
  it {is_expected.to validate_presence_of :start_time}
  it {skip; is_expected.to accept_nested_attributes_for :participants} # geht das?

  let(:project) { FactoryGirl.create(:project) }
  let(:user1) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:meeting) { FactoryGirl.create(:meeting, :project => project, :author => user1) }
  let(:agenda) do
    meeting.create_agenda :text => "Meeting Agenda text"
    meeting.agenda(true) # avoiding stale object errors
  end

  let(:role) { FactoryGirl.create(:role, :permissions => [:view_meetings]) }

  before do
    @m = FactoryGirl.build :meeting, :title => "dingens"
  end

  describe "to_s" do
    it {expect(@m.to_s).to eq("dingens")}
  end

  describe "start_date" do
    it {expect(@m.start_date).to eq(Date.tomorrow)}
  end

  describe "start_month" do
    it {expect(@m.start_month).to eq(Date.tomorrow.month)}
  end

  describe "start_year" do
    it {expect(@m.start_year).to eq(Date.tomorrow.year)}
  end

  describe "end_time" do
    it {expect(@m.end_time).to eq(Date.tomorrow + 11.hours)}
  end

  describe "time-sorted finder" do
    it {skip}
  end

  describe "Journalized Objects" do
    before(:each) do
      @project ||= FactoryGirl.create(:project_with_types)
      @current = FactoryGirl.create(:user, :login => "user1", :mail => "user1@users.com")
      allow(User).to receive(:current).and_return(@current)
    end

    it 'should work with meeting' do
      @meeting ||= FactoryGirl.create(:meeting, :title => "Test", :project => @project, :author => @current)

      initial_journal = @meeting.journals.first
      recreated_journal = @meeting.recreate_initial_journal!
      expect(initial_journal.identical?(recreated_journal)).to be true
    end
  end

  describe "all_changeable_participants" do
    describe "WITH a user having the view_meetings permission" do
      before do
        project.add_member user1, [role]
        project.save!
      end

      it "should contain the user" do
        expect(meeting.all_changeable_participants).to eq([user1])
      end
    end

    describe "WITH a user not having the view_meetings permission" do
      let(:role2) { FactoryGirl.create(:role, :permissions => []) }

      before do
        # adding both users so that the author is valid
        project.add_member user1, [role]
        project.add_member user2, [role2]

        project.save!
      end

      it "should not contain the user" do
        expect(meeting.all_changeable_participants.include?(user2)).to be_falsey
      end
    end

    describe "WITH a user being locked but invited" do
      let(:locked_user) { FactoryGirl.create(:locked_user) }
      before do
        meeting.participants_attributes = [{"user_id" => locked_user.id, "invited" => 1}]
      end

      it "should contain the user" do
        expect(meeting.all_changeable_participants.include?(locked_user)).to be_truthy
      end
    end
  end

  describe "participants and author as watchers" do
    before do
      project.add_member user1, [role]
      project.add_member user2, [role]

      project.save!

      meeting.participants.build(:user => user2)
      meeting.save!
    end

    it { expect(meeting.watchers.collect(&:user)).to match_array([user1, user2]) }
  end

  describe :close_agenda_and_copy_to_minutes do
    before do
      agenda #creating it

      meeting.close_agenda_and_copy_to_minutes!
    end

    it "should create a meeting with the agenda's text" do
      expect(meeting.minutes.text).to eq(meeting.agenda.text)
    end

    it "should close the agenda" do
      expect(meeting.agenda.locked?).to be_truthy
    end
  end

  describe "Copied meetings" do
    before do
      project.add_member user1, [role]
      project.add_member user2, [role]

      project.save!

      meeting.start_time = DateTime.new(2013,3,27,15,35)
      meeting.participants.build(:user => user2)
      meeting.save!
    end

    it "should have the same start_time as the original meeting" do
      copy = meeting.copy({})
      expect(copy.start_time).to eq(meeting.start_time)
    end

    it "should delete the copied meeting author if no author is given as parameter" do
      copy = meeting.copy({})
      expect(copy.author).to be_nil
    end

    it "should set the author to the provided author if one is given" do
      copy = meeting.copy :author => user2
      expect(copy.author).to eq(user2)
    end

    it "should clear participant ids and attended flags for all copied attendees" do
      copy = meeting.copy({})
      expect(copy.participants.all?{ |p| p.id.nil? && !p.attended }).to be_truthy
    end
  end
end
