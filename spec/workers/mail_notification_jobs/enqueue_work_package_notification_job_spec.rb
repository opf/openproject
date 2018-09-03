#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe EnqueueWorkPackageNotificationJob, type: :model do
  let(:project) { FactoryBot.create(:project) }
  let(:role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }
  let(:recipient) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role, login: "johndoe")
  end
  let(:author) { FactoryBot.create(:user, login: "marktwain") }
  let(:work_package) do
    FactoryBot.create(:work_package,
                       project: project,
                       author: author,
                       assigned_to: recipient)
  end
  let(:journal) { work_package.journals.first }
  subject { described_class.new(journal.id, author.id) }

  before do
    # make sure no other calls are made due to WP creation/update
    allow(OpenProject::Notifications).to receive(:send) # ... and do nothing
  end

  it 'sends a mail' do
    expect(Delayed::Job).to receive(:enqueue).with(an_instance_of(DeliverWorkPackageNotificationJob), any_args)
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
        .with(an_instance_of(DeliverWorkPackageNotificationJob), any_args)
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
      service = WorkPackages::UpdateService.new(user: author, work_package: work_package)

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
        expect(Delayed::Job)
          .to receive(:enqueue)
          .with(an_instance_of(DeliverWorkPackageNotificationJob), any_args)
          .once
        described_class.new(journal_1.id, author.id).perform
      end

      it 'Job 2 sends no mails' do
        expect(Delayed::Job).not_to receive(:enqueue)
        described_class.new(journal_2.id, author.id).perform
      end

      it 'Job 3 sends one mail for journal (2,3)' do
        expect(Delayed::Job)
          .to receive(:enqueue)
          .with(an_instance_of(DeliverWorkPackageNotificationJob), any_args)
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
        expect(Delayed::Job)
          .to receive(:enqueue)
          .with(an_instance_of(DeliverWorkPackageNotificationJob), any_args)
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
                                  .with(an_instance_of(DeliverWorkPackageNotificationJob), any_args)
                                  .once
        described_class.new(journal_2.id, author.id).perform
      end

      it 'Job 3 sends one mail for journal 3' do
        expect(Delayed::Job).to receive(:enqueue)
                                  .with(an_instance_of(DeliverWorkPackageNotificationJob), any_args)
                                  .once
        described_class.new(journal_3.id, author.id).perform
      end
    end
  end

  describe "#text_for_mentions" do
    it "returns a text" do
      subject.perform
      expect(subject.send(:text_for_mentions)).to be_a String
    end

    context "subject and description changed" do
      let(:title) { 'New subject' }
      let(:description) { 'New description' }
      let(:notes) { 'Nice notes!' }

      subject { described_class.new(work_package.journals.last.id, author.id) }

      before do
        work_package.subject = title
        work_package.description = description
        work_package.save!

        work_package.journals.last.notes = notes
        work_package.journals.last.save

        subject.perform
      end

      it "returns notes, subject and description" do
        expect(subject.send(:text_for_mentions)).not_to be_blank
        expect(subject.send(:text_for_mentions)).to match title
        expect(subject.send(:text_for_mentions)).to match description
        expect(subject.send(:text_for_mentions)).to match notes
      end
    end
  end

  describe "#mentioned" do
    subject do
      instance = described_class.new(journal.id, author.id)
      instance.perform

      allow(instance)
        .to receive(:text_for_mentions)
        .and_return(added_text)

      instance.send(:mentioned)
    end

    context 'for users' do
      context "mentioned is allowed to view the work package" do
        context "The added text contains a login name" do
          let(:added_text) { "Hello user:\"#{recipient.login}\"" }

          context "that is pretty normal word" do
            it "detects the user" do
              is_expected
                .to match_array [recipient]
            end
          end

          context "that is an email address" do
            let(:recipient) do
              FactoryBot.create(:user,
                                 member_in_project: project,
                                 member_through_role: role,
                                 login: "foo@bar.com")
            end

            it "detects the user" do
              is_expected
                .to match_array [recipient]
            end
          end
        end

        context "The added text contains a user ID" do
          let(:added_text) { "Hello user##{recipient.id}" }

          it "detects the user" do
            is_expected
              .to match_array [recipient]
          end
        end

        context "the recipient turned off all mail notifications" do
          let(:recipient) do
            FactoryBot.create(:user,
                               member_in_project: project,
                               member_through_role: role,
                               mail_notification: 'none')
          end

          let(:added_text) do
            "Hello user:\"#{recipient.login}\", hey user##{recipient.id}"
          end

          it "no user gets detected" do
            is_expected
              .to be_empty
          end
        end
      end

      context "mentioned user is not allowed to view the work package" do
        let(:recipient) do
          FactoryBot.create(:user,
                             login: "foo@bar.com")
        end
        let(:added_text) do
          "Hello user:#{recipient.login}, hey user##{recipient.id}"
        end

        it "no user gets detected" do
          is_expected
            .to be_empty
        end
      end
    end

    context 'for groups' do
      let(:group_member) { FactoryBot.create(:user) }

      let(:group) do
        FactoryBot.create(:group) do |group|
          group.users << group_member

          FactoryBot.create(:member,
                             project: project,
                             principal: group,
                             roles: [role])
        end
      end

      let(:added_text) do
        "Hello group##{group.id}"
      end

      context 'group member is allowed to view the work package' do
        context 'user wants to receive notifications' do
          it "group member gets detected" do
            is_expected
              .to match_array([group_member])
          end
        end

        context 'user disabled notifications' do
          let(:group_member) { FactoryBot.create(:user, mail_notification: User::USER_MAIL_OPTION_NON.first) }

          it "group member is ignored" do
            is_expected
              .to be_empty
          end
        end
      end

      context 'group is not allowed to view the work package' do
        let(:role) { FactoryBot.create(:role, permissions: []) }

        it "group member is ignored" do
          is_expected
            .to be_empty
        end

        context 'but group member is allowed individually' do
          before do
            FactoryBot.create(:member,
                               project: project,
                               principal: group_member,
                               roles: [FactoryBot.create(:role, permissions: [:view_work_packages])])
          end

          it "group member gets detected" do
            is_expected
              .to match_array([group_member])
          end
        end
      end
    end
  end
end
