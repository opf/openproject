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

describe MeetingContentsController do
  shared_let(:role) { FactoryBot.create(:role, permissions: [:view_meetings]) }
  shared_let(:project) { FactoryBot.create(:project) }
  shared_let(:author) { FactoryBot.create(:user, member_in_project: project, member_through_role: role) }
  shared_let(:watcher1) { FactoryBot.create(:user, member_in_project: project, member_through_role: role) }
  shared_let(:watcher2) { FactoryBot.create(:user, member_in_project: project, member_through_role: role) }
  shared_let(:meeting) do
    User.execute_as author do
      FactoryBot.create(:meeting, author: author, project: project)
    end
  end
  shared_let(:meeting_agenda) do
    User.execute_as author do
      FactoryBot.create(:meeting_agenda, meeting: meeting)
    end
  end

  before(:each) do
    ActionMailer::Base.deliveries = []
    allow_any_instance_of(MeetingContentsController).to receive(:find_content)
    allow(controller).to receive(:authorize)
    meeting.participants.merge([meeting.participants.build(user: watcher1, invited: true, attended: false),
                                meeting.participants.build(user: watcher2, invited: true, attended: false)])
    meeting.save!
    controller.instance_variable_set(:@content, meeting_agenda.meeting.agenda)
    controller.instance_variable_set(:@content_type, 'meeting_agenda')
  end

  shared_examples_for 'delivered by mail' do
    before { put action, params: { meeting_id: meeting.id } }

    it { expect(ActionMailer::Base.deliveries.count).to eql(mail_count) }
  end

  describe 'PUT' do
    describe 'notify' do
      let(:action) { 'notify' }

      context 'when author no_self_notified property is true' do
        before do
          author.pref[:no_self_notified] = true
          author.save!
        end

        it_behaves_like 'delivered by mail' do
          let(:mail_count) { 2 }
        end
      end

      context 'when author no_self_notified property is false' do
        before do
          author.pref[:no_self_notified] = false
          author.save!
        end

        it_behaves_like 'delivered by mail' do
          let(:mail_count) { 3 }
        end
      end

      context 'with an error during deliver' do
        before do
          author.pref[:no_self_notified] = false
          author.save!
          allow(MeetingMailer).to receive(:content_for_review).and_raise(Net::SMTPError)
        end

        it 'does not raise an error' do
          expect { put 'notify', params: { meeting_id: meeting.id } }.to_not raise_error
        end

        it 'produces a flash message containing the mail addresses raising the error' do
          put 'notify',  params: { meeting_id: meeting.id }
          meeting.participants.each do |participant|
            expect(flash[:error]).to include(participant.name)
          end
        end
      end
    end

    describe 'icalendar' do
      let(:action) { 'icalendar' }

      context 'when author no_self_notified property is true' do
        before do
          author.pref[:no_self_notified] = true
          author.save!
        end

        it_behaves_like 'delivered by mail' do
          let(:mail_count) { 3 }
        end
      end

      context 'when author no_self_notified property is false' do
        before do
          author.pref[:no_self_notified] = false
          author.save!
        end

        it_behaves_like 'delivered by mail' do
          let(:mail_count) { 3 }
        end
      end

      context 'with an error during deliver' do
        before do
          author.pref[:no_self_notified] = false
          author.save!
          allow(MeetingMailer).to receive(:content_for_review).and_raise(Net::SMTPError)
        end

        it 'does not raise an error' do
          expect { put 'notify', params: { meeting_id: meeting.id } }.to_not raise_error
        end

        it 'produces a flash message containing the mail addresses raising the error' do
          put 'notify',  params: { meeting_id: meeting.id }
          meeting.participants.each do |participant|
            expect(flash[:error]).to include(participant.name)
          end
        end
      end
    end
  end
end
