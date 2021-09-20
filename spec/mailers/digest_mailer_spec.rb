#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe DigestMailer, type: :mailer do
  include OpenProject::ObjectLinking
  include ActionView::Helpers::UrlHelper
  include OpenProject::StaticRouting::UrlHelpers
  include Redmine::I18n

  let(:recipient) do
    FactoryBot.build_stubbed(:user).tap do |u|
      allow(User)
        .to receive(:find)
              .with(u.id)
              .and_return(u)
    end
  end
  let(:project1) { FactoryBot.build_stubbed(:project) }

  let(:work_package) do
    FactoryBot.build_stubbed(:work_package,
                             type: FactoryBot.build_stubbed(:type))
  end
  let(:journal) do
    FactoryBot.build_stubbed(:work_package_journal,
                             notes: 'Some notes').tap do |j|
      allow(j)
        .to receive(:details)
              .and_return({ "subject" => ["old subject", "new subject"] })
    end
  end
  let(:notifications) do
    [FactoryBot.build_stubbed(:notification,
                              resource: work_package,
                              journal: journal,
                              project: project1)].tap do |notifications|
      allow(Notification)
        .to receive(:where)
              .and_return(notifications)

      allow(notifications)
        .to receive(:includes)
              .and_return(notifications)
    end
  end

  describe '#work_packages' do
    subject(:mail) { described_class.work_packages(recipient.id, notifications.map(&:id)) }

    let(:mail_body) { mail.body.parts.detect { |part| part['Content-Type'].value == 'text/html' }.body.to_s }

    it 'notes the day and the number of notifications in the subject' do
      expect(mail.subject)
        .to eql "OpenProject - 1 unread notification"
    end

    it 'sends to the recipient' do
      expect(mail.to)
        .to match_array [recipient.mail]
    end

    it 'sets the expected message_id header' do
      allow(Time)
        .to receive(:current)
              .and_return(Time.current)

      expect(mail['Message-ID']&.value)
        .to eql "<openproject.digest-#{recipient.id}-#{Time.current.strftime('%Y%m%d%H%M%S')}@example.net>"
    end

    it 'sets the expected openproject headers' do
      expect(mail['X-OpenProject-User']&.value)
        .to eql recipient.name
    end

    it 'includes the notifications grouped by work package' do
      time_stamp = journal.created_at.strftime('%I:%M %p')
      expect(mail_body)
        .to have_text("Hey #{recipient.firstname}!")

      expected_notification_subject = "#{work_package.type.name.upcase} #{work_package.subject}"
      expect(mail_body)
        .to have_text(expected_notification_subject, normalize_ws: true)

      expected_notification_header = "#{work_package.status.name} ##{work_package.id} - #{work_package.project}"
      expect(mail_body)
        .to have_text(expected_notification_header, normalize_ws: true)

      expected_journal_text = "Comment added at #{time_stamp} by #{recipient.name}"
      expect(mail_body)
        .to have_text(expected_journal_text, normalize_ws: true)

      expected_details_text = "Subject changed from old subject to new subject at #{time_stamp} by #{recipient.name}"
      expect(mail_body)
        .to have_text(expected_details_text, normalize_ws: true)
    end

    context 'with only a deleted work package for the digest' do
      let(:work_package) { nil }

      it `is a NullMail which isn't sent` do
        expect(mail.body)
          .to eql ''

        expect(mail.header)
          .to eql({})
      end
    end

    describe 'journal details in plain mail', with_settings: { plain_text_mail: '1' } do
      subject(:mail) { described_class.work_packages(recipient.id, notifications.map(&:id)).body.encoded.gsub("\r\n", "\n") }

      context 'with changed done ratio' do
        before do
          allow(journal).to receive(:details).and_return('done_ratio' => [40, 100])
        end

        it 'displays changed done ratio' do
          expect(subject).to include("Progress (%) changed from 40 to 100")
        end
      end

      context 'with new done ratio' do
        before do
          allow(journal).to receive(:details).and_return('done_ratio' => [nil, 100])
        end

        it 'displays new done ratio' do
          expect(subject).to include("Progress (%) changed from 0 to 100")
        end
      end

      context 'with deleted done ratio' do
        before do
          allow(journal).to receive(:details).and_return('done_ratio' => [50, nil])
        end

        it 'displays deleted done ratio' do
          expect(subject).to include("Progress (%) changed from 50 to 0")
        end
      end

      describe 'start_date attribute' do
        before do
          allow(journal).to receive(:details).and_return('start_date' => %w[2010-01-01 2010-01-31])
        end

        it 'old date should be formatted' do
          expect(subject).to match('01/01/2010')
        end

        it 'new date should be formatted' do
          expect(subject).to match('01/31/2010')
        end
      end

      describe 'due_date attribute' do
        before do
          allow(journal).to receive(:details).and_return('due_date' => %w[2010-01-01 2010-01-31])
        end

        it 'old date should be formatted' do
          expect(subject).to match('01/01/2010')
        end

        it 'new date should be formatted' do
          expect(subject).to match('01/31/2010')
        end
      end

      describe 'project attribute' do
        let(:project1) { FactoryBot.create(:project) }
        let(:project2) { FactoryBot.create(:project) }

        before do
          allow(journal).to receive(:details).and_return('project_id' => [project1.id, project2.id])
        end

        it "shows the old project's name" do
          expect(subject).to match(project1.name)
        end

        it "shows the new project's name" do
          expect(subject).to match(project2.name)
        end
      end

      describe 'attribute issue status' do
        let(:status1) { FactoryBot.create(:status) }
        let(:status2) { FactoryBot.create(:status) }

        before do
          allow(journal).to receive(:details).and_return('status_id' => [status1.id, status2.id])
        end

        it "shows the old status' name" do
          expect(subject).to match(status1.name)
        end

        it "shows the new status' name" do
          expect(subject).to match(status2.name)
        end
      end

      describe 'attribute type' do
        let(:type1) { FactoryBot.create(:type_standard) }
        let(:type2) { FactoryBot.create(:type_bug) }

        before do
          allow(journal).to receive(:details).and_return('type_id' => [type1.id, type2.id])
        end

        it "shows the old type's name" do
          expect(subject).to match(type1.name)
        end

        it "shows the new type's name" do
          expect(subject).to match(type2.name)
        end
      end

      describe 'attribute assigned to' do
        let(:assignee1) { FactoryBot.create(:user) }
        let(:assignee2) { FactoryBot.create(:user) }

        before do
          allow(journal).to receive(:details).and_return('assigned_to_id' => [assignee1.id, assignee2.id])
        end

        it "shows the old assignee's name" do
          expect(subject).to match(assignee1.name)
        end

        it "shows the new assignee's name" do
          expect(subject).to match(assignee2.name)
        end
      end

      describe 'attribute priority' do
        let(:priority1) { FactoryBot.create(:priority) }
        let(:priority2) { FactoryBot.create(:priority) }

        before do
          allow(journal).to receive(:details).and_return('priority_id' => [priority1.id, priority2.id])
        end

        it "shows the old priority's name" do
          expect(subject).to match(priority1.name)
        end

        it "shows the new priority's name" do
          expect(subject).to match(priority2.name)
        end
      end

      describe 'attribute category' do
        let(:category1) { FactoryBot.create(:category) }
        let(:category2) { FactoryBot.create(:category) }

        before do
          allow(journal).to receive(:details).and_return('category_id' => [category1.id, category2.id])
        end

        it "shows the old category's name" do
          expect(subject).to match(category1.name)
        end

        it "shows the new category's name" do
          expect(subject).to match(category2.name)
        end
      end

      describe 'attribute version' do
        let(:version1) { FactoryBot.create(:version) }
        let(:version2) { FactoryBot.create(:version) }

        before do
          allow(journal).to receive(:details).and_return('version_id' => [version1.id, version2.id])
        end

        it "shows the old version's name" do
          expect(subject).to match(version1.name)
        end

        it "shows the new version's name" do
          expect(subject).to match(version2.name)
        end
      end

      describe 'attribute estimated hours' do
        let(:estimated_hours1) { 30.5678 }
        let(:estimated_hours2) { 35.912834 }

        before do
          allow(journal).to receive(:details).and_return('estimated_hours' => [estimated_hours1, estimated_hours2])
        end

        it 'shows the old estimated hours' do
          expect(subject).to match('%.2f' % estimated_hours1)
        end

        it 'shows the new estimated hours' do
          expect(subject).to match('%.2f' % estimated_hours2)
        end
      end

      describe 'custom field' do
        let(:expected_text) { 'original, unchanged text' }
        let(:expected_text2) { 'modified, new text' }
        let(:custom_field) do
          FactoryBot.create :work_package_custom_field,
                            field_format: 'text'
        end

        before do
          allow(journal).to receive(:details).and_return("custom_fields_#{custom_field.id}" => [expected_text, expected_text2])
        end

        it 'shows the old custom field value' do
          expect(subject).to match(expected_text)
        end

        it 'shows the new custom field value' do
          expect(subject).to match(expected_text2)
        end
      end
    end

    describe 'journal details in html mail' do
      subject(:mail) do
        described_class.work_packages(recipient.id, notifications.map(&:id)).body.parts[1].body.to_s.gsub("\r\n", "\n")
      end

      let(:expected_translation) do
        I18n.t(:done_ratio, scope: %i[activerecord
                                      attributes
                                      work_package])
      end
      let(:expected_prefix) { "<strong>#{expected_translation}</strong>" }

      context 'with changed done ratio' do
        let(:expected) do
          "#{expected_prefix} changed from <i title=\"40\">40</i> <strong>to</strong> <i title=\"100\">100</i>"
        end

        before do
          allow(journal).to receive(:details).and_return('done_ratio' => [40, 100])
        end

        it 'displays changed done ratio' do
          expect(subject).to include(expected)
        end
      end

      context 'with changed subject to long value' do
        let(:old_subject) { 'foo' }
        let(:new_subject) { 'abcd' * 25 }
        let(:expected) do
          "<strong>Subject</strong> changed from <i title=\"#{old_subject}\">#{old_subject}</i> <br/><strong>to</strong> " \
            "<i title=\"#{new_subject}\">#{new_subject}</i>"
        end

        before do
          allow(journal).to receive(:details).and_return('subject' => [old_subject, new_subject])
        end

        it 'displays changed subject with newline' do
          expect(subject).to include(expected)
        end
      end

      context 'with new done ratio' do
        let(:expected) do
          "#{expected_prefix} changed from <i title=\"0\">0</i> <strong>to</strong> <i title=\"100\">100</i>"
        end

        before do
          allow(journal).to receive(:details).and_return('done_ratio' => [nil, 100])
        end

        it 'displays new done ratio' do
          expect(subject).to include(expected)
        end
      end

      context 'with deleted done ratio' do
        let(:expected) { "#{expected_prefix} changed from <i title=\"50\">50</i> <strong>to</strong> <i title=\"0\">0</i>" }

        before do
          allow(journal).to receive(:details).and_return('done_ratio' => [50, nil])
        end

        it 'displays deleted done ratio' do
          expect(subject).to include(expected)
        end
      end

      describe 'attachments', with_settings: { host_name: "mydomain.foo" } do
        shared_let(:attachment) { FactoryBot.create(:attachment) }
        let(:journal) do
          FactoryBot.build_stubbed(:work_package_journal)
        end

        context 'when added' do # rubocop:disable Rspec/NestedGroups
          before do
            allow(journal).to receive(:details).and_return("attachments_#{attachment.id}" => [nil, attachment.filename])
          end

          it "shows the attachment's filename" do
            expect(subject).to include(attachment.filename)
          end

          it "links correctly" do
            expect(subject).to include("<a href=\"http://mydomain.foo/api/v3/attachments/#{attachment.id}/content\">")
          end

          context 'with a suburl', with_config: { rails_relative_url_root: '/rdm' } do # rubocop:disable Rspec/NestedGroups
            it "links correctly" do
              expect(subject).to include("<a href=\"http://mydomain.foo/rdm/api/v3/attachments/#{attachment.id}/content\">")
            end
          end

          it "shows status 'added'" do
            expect(subject).to include('added')
          end

          it "shows no status 'deleted'" do
            expect(subject).not_to include('deleted')
          end
        end

        context 'when removed' do # rubocop:disable Rspec/NestedGroups
          before do
            allow(journal).to receive(:details).and_return("attachments_#{attachment.id}" => [attachment.filename, nil])
          end

          it "shows the attachment's filename" do
            expect(subject).to include(attachment.filename)
          end

          it "shows no status 'added'" do
            expect(subject).not_to include('added')
          end

          it "shows status 'deleted'" do
            expect(subject).to include('deleted')
          end
        end
      end
    end
  end
end
