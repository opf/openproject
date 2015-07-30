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

describe DeliverWorkPackageNotificationJob, type: :model do
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
    # make sure no actual calls make it into the UserMailer
    allow(UserMailer).to receive(:work_package_added).and_return(double('mail', deliver: nil))
    allow(UserMailer).to receive(:work_package_updated).and_return(double('mail', deliver: nil))
  end

  it 'sends a mail' do
    expect(UserMailer).to receive(:work_package_added).with(recipient, work_package, author)
    subject.perform
  end

  context 'non-existant journal' do
    before do
      journal.destroy
    end

    it 'sends no mail' do
      expect(UserMailer).not_to receive(:work_package_added)
      subject.perform
    end
  end

  context 'non-existant author' do
    before do
      author.destroy
    end

    it 'sends a mail' do
      expect(UserMailer).to receive(:work_package_added)
      subject.perform
    end

    it 'uses the deleted user as author' do
      expect(UserMailer).to receive(:work_package_added)
                              .with(recipient, work_package, DeletedUser.first)

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
      expect(UserMailer).not_to receive(:work_package_added)
      expect(UserMailer).not_to receive(:work_package_updated)
      subject.perform
    end
  end

  context 'update journal' do
    let(:journal) { work_package.journals.last }

    before do
      work_package.add_journal(FactoryGirl.create(:user), 'a comment')
      work_package.save!
    end

    it 'sends an update mail' do
      expect(UserMailer).to receive(:work_package_updated)
      subject.perform
    end

    it 'sends a mail for the aggregated journal' do
      expected = Journal::AggregatedJournal.aggregated_journals(journable: work_package).last
      expect(UserMailer).to receive(:work_package_updated) do |_recipient, journal, _author|
        expect(journal.id).to eq expected.id
        expect(journal.notes_id).to eq expected.notes_id

        double('mail', deliver: nil)
      end
      subject.perform
    end
  end

  describe 'impersonation' do
    describe 'the recipient should become the current user during mail creation' do
      before do
        expect(UserMailer).to receive(:work_package_added) do
          expect(User.current).to eql(recipient)
          double('mail', deliver: nil)
        end
      end

      it { subject.perform }
    end

    context 'for a known current user' do
      let(:current_user) { FactoryGirl.create(:user) }

      it 'resets to the previous current user after running' do
        User.current = current_user
        subject.perform
        expect(User.current).to eql(current_user)
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
    # Therefore a Job needs to check whether it has hidden another job and execute
    # its notifications too.

    before do
      change = { subject: 'new subject' }
      note = { notes: 'a comment' }

      expect(work_package.update_by!(author, note)).to be_truthy
      work_package.reload
      expect(work_package.update_by!(author, change)).to be_truthy
      work_package.reload
      expect(work_package.update_by!(author, note)).to be_truthy
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
        expect(UserMailer).to receive(:work_package_updated).once
        described_class.new(journal_1.id, author.id).perform
      end

      it 'Job 2 sends no mails' do
        expect(UserMailer).not_to receive(:work_package_updated)
        described_class.new(journal_2.id, author.id).perform
      end

      it 'Job 3 sends one mail for journal (2,3)' do
        expect(UserMailer).to receive(:work_package_updated).once
        described_class.new(journal_3.id, author.id).perform
      end
    end

    context 'journal 3 created after timeout of 1, but inside of timeout for 2' do
      # Job 1 will not send a mail because it does not know about journal 3
      #   (thinking 2 will take its mail)
      # Job 3 will have to take over the mail for Job 1
      # Even if Job 1 knew of journal 3 (due to late execution), it was not allowed to send a mail
      #   (that would cause Job 3 to deliver a duplicate mail)

      before do
        journal_2.created_at = journal_1.created_at + (timeout / 2)
        journal_3.created_at = journal_1.created_at + timeout + 5.seconds
        journal_2.save!
        journal_3.save!
      end

      it 'Job 1 sends no mails' do
        expect(UserMailer).not_to receive(:work_package_updated)
        described_class.new(journal_1.id, author.id).perform
      end

      it 'Job 2 sends no mails' do
        expect(UserMailer).not_to receive(:work_package_updated)
        described_class.new(journal_2.id, author.id).perform
      end

      it 'Job 3 sends mails for journals 1 + (2,3)' do
        expect(UserMailer).to receive(:work_package_updated).twice
        described_class.new(journal_3.id, author.id).perform
      end
    end

    context 'journal 3 created after timeout of 1 and 2' do
      # This is a normal case, just to ensure that Job 3 will recognize it is not responsible for
      # (1,2).

      before do
        journal_2.created_at = journal_1.created_at + (timeout / 2)
        journal_3.created_at = journal_2.created_at + timeout + 5.seconds
        journal_2.save!
        journal_3.save!
      end

      it 'Job 1 sends no mails' do
        expect(UserMailer).not_to receive(:work_package_updated)
        described_class.new(journal_1.id, author.id).perform
      end

      it 'Job 2 sends one mail for journal (1, 2)' do
        expect(UserMailer).to receive(:work_package_updated).once
        described_class.new(journal_2.id, author.id).perform
      end

      it 'Job 3 sends one mail for journal 3' do
        expect(UserMailer).to receive(:work_package_updated).once
        described_class.new(journal_3.id, author.id).perform
      end
    end
  end
end
