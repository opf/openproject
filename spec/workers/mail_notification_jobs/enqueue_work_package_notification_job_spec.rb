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

describe EnqueueWorkPackageNotificationJob, type: :model do
  let(:project) { FactoryGirl.create(:project) }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:recipient) {
    FactoryGirl.create(:user, member_in_project: project, member_through_role: role)
  }
  let(:author) { FactoryGirl.create(:user) }
  let(:work_package) {
    FactoryGirl.create(:work_package,
                       project: project,
                       author: author,
                       assigned_to: recipient)
  }
  let(:journal) { work_package.journals.first }
  subject { described_class.new(journal.id, author.id) }

  before do
    # make sure no other calls are made due to WP creation/update
    allow(OpenProject::Notifications).to receive(:send) # ... and do nothing
  end

  it 'sends a mail' do
    expect(Delayed::Job).to receive(:enqueue).with(an_instance_of DeliverWorkPackageNotificationJob)
    subject.perform
  end

  context 'non-existant journal' do
    before do
      journal.destroy
    end

    it 'sends no mail' do
      expect(Delayed::Job).not_to receive(:enqueue)
      subject.perform
    end
  end

  context 'non-existant author' do
    before do
      author.destroy
    end

    it 'sends a mail' do
      expect(Delayed::Job)
        .to receive(:enqueue)
        .with(an_instance_of DeliverWorkPackageNotificationJob)
      subject.perform
    end
  end

  context 'outdated journal' do
    before do
      # make sure there is a later journal, that supersedes the original one
      work_package.subject = 'changed subject'
      work_package.save!
    end

    it 'does not send any mails' do
      expect(Delayed::Job).not_to receive(:enqueue)
      subject.perform
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

    before do
      change = { subject: 'new subject' }
      note = { journal_notes: 'a comment' }

      allow(WorkPackages::UpdateContract).to receive(:new).and_return(NoopContract.new)
      service = UpdateWorkPackageService.new(user: author, work_package: work_package)

      expect(service.call(attributes: note)).to be_success
      expect(service.call(attributes: change)).to be_success
      expect(service.call(attributes: note)).to be_success
    end

    let(:timeout) { Setting.journal_aggregation_time_minutes.to_i.minutes }
    let(:journal_1) { work_package.journals[1] }
    let(:journal_2) { work_package.journals[2] }
    let(:journal_3) { work_package.journals[3] }

    context 'all changes happen within the timeout of journal 1' do
      # The job for 1 will know, that Journal 3 took its addition.
      # The job for 2 will know, that it has become part of Journal 3.
      #  -> no special behaviour required

      it 'Job 1 sends one mail for journal 1' do
        expect(Delayed::Job).to receive(:enqueue)
                                  .with(an_instance_of DeliverWorkPackageNotificationJob)
                                  .once
        described_class.new(journal_1.id, author.id).perform
      end

      it 'Job 2 sends no mails' do
        expect(Delayed::Job).not_to receive(:enqueue)
        described_class.new(journal_2.id, author.id).perform
      end

      it 'Job 3 sends one mail for journal (2,3)' do
        expect(Delayed::Job).to receive(:enqueue)
                                  .with(an_instance_of DeliverWorkPackageNotificationJob)
                                  .once
        described_class.new(journal_3.id, author.id).perform
      end
    end

    context 'journal 3 created after timeout of 1, but inside of timeout for 2' do
      # Job 1 will not send a mail because it does not know about journal 3
      #   (thinking 2 will take its mail)
      # The mail of Job 1 is taken over by the JournalNotificationMailer for Journal 3
      # Even if Job 1 knew of journal 3 (due to late execution), it was not allowed to send a mail
      #   (that would cause a duplicate mail delivery)

      before do
        journal_2.created_at = journal_1.created_at + (timeout / 2)
        journal_3.created_at = journal_1.created_at + timeout + 5.seconds
        journal_2.save!
        journal_3.save!
      end

      it 'Job 1 sends no mails' do
        expect(Delayed::Job).not_to receive(:enqueue)
        described_class.new(journal_1.id, author.id).perform
      end

      it 'Job 2 sends no mails' do
        expect(Delayed::Job).not_to receive(:enqueue)
        described_class.new(journal_2.id, author.id).perform
      end

      it 'Job 3 sends one mail for (2,3)' do
        expect(Delayed::Job).to receive(:enqueue)
                                  .with(an_instance_of DeliverWorkPackageNotificationJob)
                                  .once
        described_class.new(journal_3.id, author.id).perform
      end
    end

    context 'journal 3 created after timeout of 1 and 2' do
      # This is a normal case again, ensuring nobody takes responsibility when not necessary.

      before do
        journal_2.created_at = journal_1.created_at + (timeout / 2)
        journal_3.created_at = journal_2.created_at + timeout + 5.seconds
        journal_2.save!
        journal_3.save!
      end

      it 'Job 1 sends no mails' do
        expect(Delayed::Job).not_to receive(:enqueue)
        described_class.new(journal_1.id, author.id).perform
      end

      it 'Job 2 sends one mail for journal (1, 2)' do
        expect(Delayed::Job).to receive(:enqueue)
                                  .with(an_instance_of DeliverWorkPackageNotificationJob)
                                  .once
        described_class.new(journal_2.id, author.id).perform
      end

      it 'Job 3 sends one mail for journal 3' do
        expect(Delayed::Job).to receive(:enqueue)
                                  .with(an_instance_of DeliverWorkPackageNotificationJob)
                                  .once
        described_class.new(journal_3.id, author.id).perform
      end
    end
  end
end
