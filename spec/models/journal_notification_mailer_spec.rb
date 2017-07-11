#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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

    login_as(user)
    allow(Setting).to receive(:notified_events).and_return(notifications)

    allow(Delayed::Job).to receive(:enqueue)
  end

  shared_examples_for 'enqueues a regular notification' do
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

      it_behaves_like 'enqueues a regular notification'

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

        it_behaves_like 'enqueues a regular notification'

        context 'WP creation' do
          let(:journal) { FactoryGirl.create(:work_package).journals.first }

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
        work_package.priority = FactoryGirl.create(:issue_priority)
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

  describe 'mail suppressing aggregation' do
    # business logic of whether to send or not to send a mail is mainly driven by the presence
    # of an aggregated journal. However, there is an edge case that could lead to a notification
    # getting lost. Sadly this is very implementation specific, so I'll describe it:
    #  Journal 1: comment
    #  Journal 2: change (this can also be multiple journals)
    #  Journal 3: comment
    #
    # The Job for the first journal will not send any mail, because Journal 2 supersedes it.
    # However, after adding Journal 3, the aggregation will look like (1), (2, 3). Therefore the
    # job for Journal 2 will not send a notification. Finally the job for Journal 3 will send a
    # notification, but only containing the changes of 2 and 3. The comment of journal 1 is lost.
    # Therefore two things have to happen:
    # - someone needs to send notifications for the hidden journal
    #   (done by JournalNotificationMailer)
    # - in case a journal is hidden, its Job is not allowed to enqueue a mail for it
    #   (because someone else will do it on behalf)
    #   This is important since late exec of a Job might cause it to _not_ skip notifications

    let(:author) { user }
    let(:notifications) { ['work_package_updated'] }
    let(:timeout) { Setting.journal_aggregation_time_minutes.to_i.minutes }

    let(:journal_1) { work_package.journals[1] }
    let(:journal_2) { work_package.journals[2] }
    let(:journal_3) { work_package.journals[3] }

    def update_by(author, attributes)
      UpdateWorkPackageService
        .new(user: author, work_package: work_package)
        .call(attributes: attributes)
    end

    shared_context 'updated until Journal 1' do
      before do
        expect(update_by(author, journal_notes: 'a comment')).to be_success
      end
    end

    shared_context 'updated until Journal 2' do
      include_context 'updated until Journal 1'

      before do
        work_package.reload
        expect(update_by(author, subject: 'new subject')).to be_success
      end
    end

    shared_context 'updated until Journal 3' do
      include_context 'updated until Journal 2'

      before do
        work_package.reload
        expect(update_by(author, journal_notes: 'a comment')).to be_success
      end
    end

    context 'all changes happen within the timeout of journal 1' do
      # The job for 1 will know, that Journal 3 took its addition.
      # The job for 2 will know, that it has become part of Journal 3.
      #  -> no special behaviour required

      describe 'Journal 1' do
        include_context 'updated until Journal 1'

        it_behaves_like 'enqueues a regular notification'
      end

      describe 'Journal 2' do
        include_context 'updated until Journal 2'

        it_behaves_like 'enqueues a regular notification'
      end

      describe 'Journal 3' do
        include_context 'updated until Journal 3'

        it_behaves_like 'enqueues a regular notification'
      end
    end

    context 'journal 3 created after timeout of 1, but inside of timeout for 2' do
      describe 'Journal 3' do
        include_context 'updated until Journal 3'

        before do
          journal_2.update_attribute(:created_at, journal_1.created_at + (timeout / 2))
          journal_3.update_attribute(:created_at, journal_1.created_at + timeout + 5.seconds)
        end

        it 'immediately delivers a mail on behalf of Journal 1' do
          expect(Delayed::Job).to receive(:enqueue)
                                    .with(
                                      an_instance_of(DeliverWorkPackageNotificationJob))
          call_listener
        end

        it 'also enqueues a regular mail' do
          expect(Delayed::Job).to receive(:enqueue)
                                    .with(
                                      an_instance_of(EnqueueWorkPackageNotificationJob),
                                      run_at: anything)
          call_listener
        end
      end
    end

    context 'journal 3 created after timeout of 1 and 2' do
      # This is a normal case again, ensuring Journal 3 takes no responsibility when not necessary.

      describe 'Journal 3' do
        include_context 'updated until Journal 3'

        before do
          journal_2.update_attribute(:created_at, journal_1.created_at + (timeout / 2))
          journal_3.update_attribute(:created_at, journal_2.created_at + timeout + 5.seconds)
        end

        it_behaves_like 'enqueues a regular notification'
      end
    end

    context 'two subsequent changes after timeout of another journal' do
      # This is a normal case again, because handling edge cases makes us miss on the normal cases

      before do
        work_package.journals.first.update_attribute(:created_at, (timeout + 5.seconds).ago)
        work_package.reload

        expect(update_by(author, done_ratio: 50)).to be_success
        work_package.reload
        expect(update_by(author, done_ratio: 60)).to be_success
        work_package.reload
      end

      it_behaves_like 'enqueues a regular notification'
    end
  end
end

describe 'initialization' do
  it 'subscribes the listener' do
    expect(JournalNotificationMailer).to receive(:distinguish_journals)
    FactoryGirl.create(:work_package)
  end
end
