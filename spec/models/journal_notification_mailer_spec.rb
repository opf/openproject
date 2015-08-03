#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'spec_helper'

describe JournalNotificationMailer do
  let(:project) { FactoryGirl.create(:project_with_types) }
  let(:user) do
    FactoryGirl.build(:user,
                      mail_notification: 'all',
                      member_in_project: project)
  end
  let(:work_package) {
    FactoryGirl.create(:work_package,
                       project: project,
                       author: user,
                       type: project.types.first)
  }
  let(:journal) { work_package.journals.last }
  let(:send_notification) { true }
  let(:notifications) { [] }

  def call_listener
    described_class.distinguish_journals(journal, send_notification)
  end

  before do
    # make sure no other calls are made due to WP creation/update
    allow(OpenProject::Notifications).to receive(:send) # ... and do nothing

    allow(User).to receive(:current).and_return(user)
    allow(Setting).to receive(:notified_events).and_return(notifications)
  end

  shared_examples_for 'sends a regular notification' do
    it do
      expect(Delayed::Job).to receive(:enqueue)
                                .with(
                                  an_instance_of(EnqueueWorkPackageNotificationJob),
                                  run_at: anything)

      # immediate delivery is not part of regular notfications, it only covers an edge-case
      expect(Delayed::Job).not_to receive(:enqueue)
                                    .with(an_instance_of DeliverWorkPackageNotificationJob)
      call_listener
    end
  end

  shared_examples_for 'handles deliveries' do |notification_setting|
    context 'setting enabled' do
      let(:notifications) { [notification_setting] }

      it_behaves_like 'sends a regular notification'

      context 'insufficient work package changes' do
        let(:journal) { another_work_package.journals.last }
        let(:another_work_package) {
          FactoryGirl.create(:work_package,
                             project: project,
                             author: user,
                             type: project.types.first)
        }
        before do
          another_work_package.add_journal(user)
          another_work_package.description = 'needs more changes'
          another_work_package.save!(validate: false)
        end

        it 'sends no notification' do
          expect(Delayed::Job).not_to receive(:enqueue)
          call_listener
        end
      end
    end

    it 'sends no notification' do
      expect(Delayed::Job).not_to receive(:enqueue)
      call_listener
    end
  end

  describe 'journal creation' do
    context 'work_package_created' do
      before do
        FactoryGirl.create(:work_package, project: project)
      end

      it_behaves_like 'handles deliveries', 'work_package_added'
    end

    context 'work_package_updated' do
      before do
        work_package.add_journal(user)
        work_package.subject = 'A change to the issue'
        work_package.save!(validate: false)
      end

      context 'setting enabled' do
        let(:notifications) { ['work_package_updated'] }

        it_behaves_like 'sends a regular notification'
      end

      it 'sends no notification' do
        expect(Delayed::Job).not_to receive(:enqueue)
        call_listener
      end
    end

    context 'work_package_note_added' do
      before do
        work_package.add_journal(user, 'This update has a note')
        work_package.save!(validate: false)
      end

      it_behaves_like 'handles deliveries', 'work_package_note_added'
    end

    context 'status_updated' do
      before do
        work_package.add_journal(user)
        work_package.status = FactoryGirl.build(:status)
        work_package.save!(validate: false)
      end

      it_behaves_like 'handles deliveries', 'status_updated'
    end

    context 'work_package_priority_updated' do
      before do
        work_package.add_journal(user)
        work_package.priority = IssuePriority.generate!
        work_package.save!(validate: false)
      end

      it_behaves_like 'handles deliveries', 'work_package_priority_updated'
    end

    context 'send_notification disabled' do
      let(:send_notification) { false }

      it 'sends no notification' do
        expect(Delayed::Job).not_to receive(:enqueue)
        call_listener
      end
    end
  end
end

describe 'initialization' do
  it 'subscribes the listener' do
    expect(JournalNotificationMailer).to receive(:distinguish_journals)
    FactoryGirl.create(:work_package)
  end
end
