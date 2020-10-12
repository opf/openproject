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

describe OpenProject::Reminders::DueIssuesReminder do
  subject do
    described_class.new(days: days, user_ids: user_ids).tap do |instance|
      instance.remind_users
    end
  end

  context 'with days set to 42' do
    let(:days) { 42 }

    context 'with user_ids unset' do
      let(:user_ids) { nil }

      let!(:user) { FactoryBot.create(:user, mail: 'foo@bar.de') }
      let!(:wp) { FactoryBot.create(:work_package, due_date: Date.tomorrow, assigned_to: user, subject: 'some issue') }

      it 'does notify the user' do
        expect(subject.notify_count).to be >= 1
        expect(ActionMailer::Base.deliveries.count).to be >= 1

        mail = ActionMailer::Base.deliveries.detect { |m| m.to.include? user.mail }
        expect(mail).to be_present
        expect(mail.body.encoded).to include("#{wp.project.name} - #{wp.type.name} ##{wp.id}: some issue")
        expect(mail.subject).to eq '1 work package(s) due in the next 42 days'
      end

      context 'with work package assigned to group' do
        let!(:group) { FactoryBot.create(:group, lastname: "Managers", members: user) }
        let!(:group_wp) do
          FactoryBot.create(:work_package, due_date: Date.tomorrow, assigned_to: group, subject: 'some group issue')
        end

        it 'notifies the user once for WPs assigend to him and another for those assigned to the group' do
          expect(subject.notify_count).to be >= 2
          expect(ActionMailer::Base.deliveries.count).to be >= 2

          mails = ActionMailer::Base.deliveries.select { |m| m.to.include? user.mail }

          expect(mails.size).to eq 2

          user_mail  = mails.detect { |mail| mail.subject == '1 work package(s) due in the next 42 days' }
          group_mail = mails.detect { |mail| mail.subject == 'For group "Managers" 1 work package(s) due in the next 42 days' }

          expect(user_mail).to be_present
          expect(group_mail).to be_present
          expect(user_mail.body.encoded).to(
            include("#{wp.project.name} - #{wp.type.name} ##{wp.id}: some issue")
          )
          expect(group_mail.body.encoded).to(
            include("#{group_wp.project.name} - #{group_wp.type.name} ##{group_wp.id}: some group issue")
          )
        end
      end
    end

    context 'with user_ids set' do
      let!(:user) { FactoryBot.create(:user, mail: 'foo@bar.de') }
      let!(:user2) { FactoryBot.create(:user, mail: 'foo@example.de') }
      let!(:wp) { FactoryBot.create(:work_package, due_date: Date.tomorrow, assigned_to: user, subject: 'some issue') }

      context 'to an unassigned user' do
        let(:user_ids) { [user2.id] }
        it 'does not notify' do
          expect(subject.notify_count).to eq 0
        end
      end

      context 'to an assigned user' do
        let(:user_ids) { [user.id] }
        it 'does notify' do
          expect(subject.notify_count).to eq 1
          expect(ActionMailer::Base.deliveries.count). to eq 1

          mail = ActionMailer::Base.deliveries.last
          expect(mail).to be_present
          expect(mail.body.encoded).to include("#{wp.project.name} - #{wp.type.name} ##{wp.id}: some issue")
          expect(mail.subject).to eq '1 work package(s) due in the next 42 days'
        end
      end
    end
  end
end
