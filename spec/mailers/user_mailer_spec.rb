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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe UserMailer, type: :mailer do
  subject(:deliveries) { ActionMailer::Base.deliveries }

  let(:type_standard) { FactoryBot.build_stubbed(:type_standard) }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:journal) do
    FactoryBot.build_stubbed(:work_package_journal).tap do |j|
      allow(j)
        .to receive(:data)
              .and_return(FactoryBot.build_stubbed(:journal_work_package_journal))
    end
  end
  let(:work_package) do
    FactoryBot.build_stubbed(:work_package,
                             type: type_standard)
  end

  let(:recipient) { FactoryBot.build_stubbed(:user) }

  before do
    allow(work_package).to receive(:reload).and_return(work_package)

    allow(journal).to receive(:journable).and_return(work_package)
    allow(journal).to receive(:user).and_return(user)

    allow(Setting).to receive(:mail_from).and_return('john@doe.com')
    allow(Setting).to receive(:host_name).and_return('mydomain.foo')
    allow(Setting).to receive(:protocol).and_return('http')
    allow(Setting).to receive(:default_language).and_return('en')
  end

  shared_examples_for 'mail is sent' do
    let(:letters_sent_count) { 1 }
    let(:mail) { deliveries.first }
    let(:html_body) { mail.body.parts.detect { |p| p.content_type.include? 'text/html' }.body.encoded }

    it 'actually sends a mail' do
      expect(deliveries.size).to eql(letters_sent_count)
    end

    it 'is sent to the recipient' do
      expect(deliveries.first.to).to include(recipient.mail)
    end

    it 'is sent from the configured address' do
      expect(deliveries.first.from).to match_array([Setting.mail_from])
    end
  end

  shared_examples_for 'multiple mails are sent' do |set_letters_sent_count|
    it_behaves_like 'mail is sent' do
      let(:letters_sent_count) { set_letters_sent_count }
    end
  end

  shared_examples_for 'mail is not sent' do
    it 'sends no mail' do
      expect(deliveries).to be_empty
    end
  end

  shared_examples_for 'does not send mails to author' do
    let(:user) { FactoryBot.build_stubbed(:user) }

    context 'when mail is for another user' do
      it_behaves_like 'mail is sent'
    end

    context 'when mail is for author' do
      let(:recipient) { user }

      it_behaves_like 'mail is not sent'
    end
  end

  describe '#with_deliveries' do
    context 'with false' do
      before do
        described_class.with_deliveries(false) do
          described_class.test_mail(recipient).deliver_now
        end
      end

      it_behaves_like 'mail is not sent'
    end

    context 'with true' do
      before do
        described_class.with_deliveries(true) do
          described_class.test_mail(recipient).deliver_now
        end
      end

      it_behaves_like 'mail is sent'
    end
  end

  describe '#test_mail' do
    let(:test_email) { 'bob.bobbi@example.com' }
    let(:recipient) { FactoryBot.build_stubbed(:user, firstname: 'Bob', lastname: 'Bobbi', mail: test_email) }

    before do
      described_class.test_mail(recipient).deliver_now
    end

    it_behaves_like 'mail is sent' do
      it 'has the expected subject' do
        expect(deliveries.first.subject)
          .to eql 'OpenProject Test'
      end

      it 'includes the url to the instance' do
        expect(deliveries.first.body.encoded)
          .to match Regexp.new("OpenProject URL: #{Setting.protocol}://#{Setting.host_name}")
      end
    end

    # the name method uses a format setting to determine how to concatenate first name
    # and last name whereby an unescaped comma will lead to have two email addresses
    # defined instead of one (['Bobbi', 'bob.bobbi@example.com'] vs. ['bob.bobbi@example.com'])
    context 'with the user name setting prone to trip up email address separation',
            with_settings: { user_format: :lastname_coma_firstname } do
      it_behaves_like 'mail is sent'
    end
  end

  describe '#work_package_added' do
    before do
      described_class.work_package_added(recipient, journal, user).deliver_now
    end

    it_behaves_like 'mail is sent' do
      it 'contains the WP subject in the mail subject' do
        expect(deliveries.first.subject)
          .to include(work_package.subject)
      end

      it 'has the desired "Precedence" header' do
        expect(deliveries.first['Precedence'].value)
          .to eql 'bulk'
      end

      it 'has the desired "Auto-Submitted" header' do
        expect(deliveries.first['Auto-Submitted'].value)
          .to eql 'auto-generated'
      end

      it 'carries a message_id' do
        expect(deliveries.first.message_id)
          .to eql(described_class.generate_message_id(journal, recipient))
      end

      it 'does not reference' do
        expect(deliveries.first.references)
          .to be_nil
      end

      context 'with plain_text_mail active', with_settings: { plain_text_mail: 1 } do
        it 'only sends plain text' do
          expect(mail.content_type)
            .to match /text\/plain/
        end
      end

      context 'with plain_text_mail inactive', with_settings: { plain_text_mail: 0 } do
        it 'sends a multipart mail' do
          expect(mail.content_type)
            .to match /multipart\/alternative/
        end
      end
    end

    it_behaves_like 'does not send mails to author'
  end

  describe '#work_package_updated' do
    before do
      described_class.work_package_updated(recipient, journal, user).deliver_now
    end

    it_behaves_like 'mail is sent' do
      it 'carries a message_id' do
        expect(deliveries.first.message_id)
          .to eql(described_class.generate_message_id(journal, recipient))
      end

      it 'references the message_id' do
        expect(deliveries.first.references)
          .to eql described_class.generate_message_id(journal, recipient)
      end

      context 'with a link' do
        let(:work_package) do
          FactoryBot.build_stubbed(:work_package,
                                   type: type_standard,
                                   description: "Some text with a reference to ##{referenced_wp.id}")
        end

        let(:referenced_wp) do
          FactoryBot.build_stubbed(:work_package)
        end

        it 'renders the link' do
          expect(html_body)
            .to have_link("##{referenced_wp.id}", href: work_package_url(referenced_wp, host: Setting.host_name))
        end

        context 'with a relative url root',
                with_config: { rails_relative_url_root: '/subpath' } do
          it 'renders the link' do
            expect(html_body)
              .to have_link("##{referenced_wp.id}",
                            href: work_package_url(referenced_wp, host: Setting.host_name, script_name: '/subpath'))
          end
        end
      end
    end

    it_behaves_like 'does not send mails to author'
  end

  describe '#work_package_watcher_changed' do
    let(:watcher_changer) { user }

    before do
      described_class.work_package_watcher_changed(work_package, recipient, watcher_changer, 'added').deliver_now
      described_class.work_package_watcher_changed(work_package, recipient, watcher_changer, 'removed').deliver_now
    end

    include_examples 'multiple mails are sent', 2

    it 'contains the WP subject in the mail subject' do
      expect(deliveries.first.subject).to include(work_package.subject)
    end
  end

  describe '#wiki_content_added' do
    let(:wiki_content) { FactoryBot.create(:wiki_content) }

    before do
      described_class.wiki_content_added(recipient, wiki_content, user).deliver_now
    end

    it_behaves_like 'mail is sent'

    it_behaves_like 'does not send mails to author'
  end

  describe '#wiki_content_updated' do
    let(:wiki_content) { FactoryBot.create(:wiki_content) }

    before do
      described_class.wiki_content_updated(recipient, wiki_content, user).deliver_now
    end

    it_behaves_like 'mail is sent'

    it 'links to the latest version diff page' do
      expect(deliveries.first.body.encoded).to include 'diff/1'
    end

    it_behaves_like 'does not send mails to author'
  end

  describe '#message_posted' do
    let(:message) do
      FactoryBot.build_stubbed(:message).tap do |msg|
        allow(msg)
          .to receive(:project)
                .and_return(msg.forum.project)
      end
    end

    before do
      described_class.message_posted(recipient, message, user).deliver_now
    end

    it_behaves_like 'mail is sent' do
      it 'carries a message_id' do
        expect(deliveries.first.message_id)
          .to eql(described_class.generate_message_id(message, recipient))
      end

      it 'has no references' do
        expect(deliveries.first.references)
          .to be_nil
      end

      it 'includes a link to the message' do
        expect(html_body)
          .to have_link(message.subject,
                        href: topic_url(message, host: Setting.host_name, r: message.id, anchor: "message-#{message.id}"))
      end
    end

    it_behaves_like 'does not send mails to author'
  end

  describe '#account_information' do
    let(:pwd) { "pAsswORd" }

    before do
      described_class.account_information(recipient, pwd).deliver_now
    end

    it_behaves_like 'mail is sent' do
      it 'includes the password' do
        expect(html_body)
          .to have_content(pwd)
      end
    end
  end

  describe '#news_added' do
    let(:news) { FactoryBot.build_stubbed(:news) }

    before do
      described_class.news_added(recipient, news, user).deliver_now
    end

    it_behaves_like 'mail is sent' do
      it 'carries a message_id' do
        expect(mail.message_id)
          .to eql(described_class.generate_message_id(news, recipient))
      end
    end

    it_behaves_like 'does not send mails to author'
  end

  describe '#news_comment_added' do
    let(:news) { FactoryBot.build_stubbed(:news) }
    let(:comment) { FactoryBot.build_stubbed(:comment, commented: news) }

    before do
      described_class.news_comment_added(recipient, comment, user).deliver_now
    end

    it_behaves_like 'mail is sent'

    it_behaves_like 'does not send mails to author'
  end

  describe '#password_lost' do
    let(:token) { FactoryBot.build_stubbed(:recovery_token) }
    let(:recipient) { token.user }

    before do
      described_class.password_lost(token).deliver_now
    end

    it_behaves_like 'mail is sent' do
      it 'includes a link to reset' do
        url = account_lost_password_url(host: Setting.host_name, token: token.value)

        expect(html_body)
          .to have_link(url,
                        href: url)
      end
    end
  end

  describe '#user_signed_up' do
    let(:token) { FactoryBot.build_stubbed(:invitation_token) }
    let(:recipient) { token.user }

    before do
      described_class.user_signed_up(token).deliver_now
    end

    it_behaves_like 'mail is sent' do
      it 'includes a link to activate' do
        url = account_activate_url(host: Setting.host_name, token: token.value)

        expect(html_body)
          .to have_link(url,
                        href: url)
      end
    end
  end

  describe '#message_id' do
    describe 'same user' do
      let(:journal2) { FactoryBot.build_stubbed(:work_package_journal) }

      before do
        allow(journal2).to receive(:journable).and_return(work_package)
        allow(journal2).to receive(:user).and_return(user)
        allow(journal2).to receive(:created_at).and_return(journal.created_at + 5.seconds)
      end

      subject do
        message_ids = [journal, journal2].each_with_object([]) do |j, l|
          l << described_class.work_package_updated(user, j).message_id
        end

        message_ids.uniq.count
      end

      it { expect(subject).to eq(2) }
    end

    describe 'same timestamp' do
      let(:user2) { FactoryBot.build_stubbed(:user) }

      before do
        allow(work_package).to receive(:recipients).and_return([user, user2])
      end

      subject do
        message_ids = [user, user2].each_with_object([]) do |u, l|
          l << described_class.work_package_updated(u, journal).message_id
        end

        message_ids.uniq.count
      end

      it { expect(subject).to eq(2) }
    end
  end

  describe 'journal details' do
    subject { described_class.work_package_updated(user, journal).body.encoded.gsub("\r\n", "\n") }

    describe 'plain text mail' do
      before do
        allow(Setting).to receive(:plain_text_mail).and_return('1')
      end

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

      describe 'attachments' do
        shared_let(:attachment) { FactoryBot.create(:attachment) }

        context 'when added' do # rubocop:disable Rspec/NestedGroups
          before do
            allow(journal).to receive(:details).and_return("attachments_#{attachment.id}" => [nil, attachment.filename])
          end

          it "shows the attachment's filename" do
            expect(subject).to match(attachment.filename)
          end

          it "links correctly" do
            expect(subject).to match("<a href=\"http://mydomain.foo/api/v3/attachments/#{attachment.id}/content\">")
          end

          context 'with a suburl', with_config: { rails_relative_url_root: '/rdm' } do # rubocop:disable Rspec/NestedGroups
            it "links correctly" do
              expect(subject).to match("<a href=\"http://mydomain.foo/rdm/api/v3/attachments/#{attachment.id}/content\">")
            end
          end

          it "shows status 'added'" do
            expect(subject).to match('added')
          end

          it "shows no status 'deleted'" do
            expect(subject).not_to match('deleted')
          end
        end

        context 'when removed' do # rubocop:disable Rspec/NestedGroups
          before do
            allow(journal).to receive(:details).and_return("attachments_#{attachment.id}" => [attachment.filename, nil])
          end

          it "shows the attachment's filename" do
            expect(subject).to match(attachment.filename)
          end

          it "shows no status 'added'" do
            expect(subject).not_to match('added')
          end

          it "shows status 'deleted'" do
            expect(subject).to match('deleted')
          end
        end
      end
    end

    describe 'html mail' do
      let(:expected_translation) do
        I18n.t(:done_ratio, scope: %i[activerecord
                                      attributes
                                      work_package])
      end
      let(:expected_prefix) { "<li><strong>#{expected_translation}</strong>" }

      before do
        allow(Setting).to receive(:plain_text_mail).and_return('0')
      end

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
    end
  end

  describe 'localization' do
    context 'with the user having a language configured',
            with_settings: { available_languages: %w[en de],
                             default_language: 'en',
                             emails_header: {
                               "de" => 'deutscher header',
                               "en" => 'english header'
                             } } do
      let(:recipient) do
        FactoryBot.build_stubbed(:user, language: 'de')
      end

      before do
        described_class.account_information(recipient, 'pwd').deliver_now
      end

      it 'uses the recipients language' do
        expect(ActionMailer::Base.deliveries.last.body.parts.detect { |p| p.content_type.include? 'text/html' }.body.encoded)
          .to include I18n.t(:mail_body_account_information, locale: :de)
      end

      it 'does not alter I18n.locale' do
        expect(I18n.locale)
          .to be :en
      end

      it 'include the user language header' do
        expect(ActionMailer::Base.deliveries.last.body.parts.detect { |p| p.content_type.include? 'text/html' }.body.encoded)
          .to include 'deutscher header'
      end
    end

    context 'with the user having no language configured',
            with_settings: { available_languages: %w[en de],
                             default_language: 'en',
                             emails_header: {
                               "de" => 'deutscher header',
                               "en" => 'english header'
                             } } do
      let(:recipient) do
        FactoryBot.build_stubbed(:user, language: '')
      end

      before do
        I18n.locale = :de

        described_class.account_information(recipient, 'pwd').deliver_now
      end

      it 'uses the default language' do
        expect(ActionMailer::Base.deliveries.last.body.parts.detect { |p| p.content_type.include? 'text/html' }.body.encoded)
          .to include I18n.t(:mail_body_account_information, locale: :en)
      end

      it 'include the default language header' do
        expect(ActionMailer::Base.deliveries.last.body.parts.detect { |p| p.content_type.include? 'text/html' }.body.encoded)
          .to include 'english header'
      end

      it 'does not alter I18n.locale' do
        expect(I18n.locale)
          .to be :de
      end
    end
  end
end
