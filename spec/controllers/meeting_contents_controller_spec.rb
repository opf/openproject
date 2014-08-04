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

require 'spec_helper'

describe MeetingContentsController do
  let(:role) { FactoryGirl.create(:role, permissions: [:view_meetings]) }
  let(:project) { FactoryGirl.create(:project) }
  let(:author) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:watcher1) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:watcher2) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:meeting) { FactoryGirl.create(:meeting, author: author, project: project) }
  let(:meeting_agenda) do
    FactoryGirl.create(:meeting_agenda, meeting: meeting)
  end

  before(:each) do
    ActionMailer::Base.deliveries = []
    MeetingContentsController.any_instance.stub(:find_content)
    controller.stub!(:authorize)
    meeting.participants.merge([meeting.participants.build(user: watcher1, invited: true, attended: false),
                                meeting.participants.build(user: watcher1, invited: true, attended: false)])
    meeting.save!
    controller.instance_variable_set(:@content, meeting_agenda.meeting.agenda)
    controller.instance_variable_set(:@content_type, 'meeting_agenda')
  end

  shared_examples_for 'delivered by mail' do
    before { put "notify", meeting_id: meeting.id }

    it { expect(ActionMailer::Base.deliveries.count).to eql(mail_count) }
  end

  describe "PUT" do
    describe "notify" do
      context "when author no_self_notified property is true" do
        before do
          author.pref[:no_self_notified] = true
          author.save!
        end

        it_behaves_like 'delivered by mail' do
          let(:mail_count) { 2 }
        end
      end

      context "when author no_self_notified property is false" do
        before do
          author.pref[:no_self_notified] = false
          author.save!
        end

        it_behaves_like 'delivered by mail' do
          let(:mail_count) { 3 }
        end
      end
    end
  end
end
