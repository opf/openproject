#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"
require_relative "shared_examples"

RSpec.describe UserMailer do
  subject(:deliveries) { ActionMailer::Base.deliveries }

  let(:type_standard) { build_stubbed(:type_standard) }
  let(:user) { build_stubbed(:user) }
  let(:journal) do
    build_stubbed(:work_package_journal).tap do |j|
      allow(j)
        .to receive(:data)
              .and_return(build_stubbed(:journal_work_package_journal))
    end
  end
  let(:work_package) do
    build_stubbed(:work_package,
                  type: type_standard)
  end

  let(:recipient) { build_stubbed(:user) }
  let(:current_time) { Time.current }

  around do |example|
    Timecop.freeze(current_time) do
      example.run
    end
  end

  before do
    allow(work_package).to receive(:reload).and_return(work_package)

    allow(journal).to receive(:journable).and_return(work_package)
    allow(journal).to receive(:user).and_return(user)

    allow(Setting).to receive(:mail_from).and_return("john@doe.com")
    allow(Setting).to receive(:host_name).and_return("mydomain.foo")
    allow(Setting).to receive(:protocol).and_return("http")
    allow(Setting).to receive(:default_language).and_return("en")
  end

  describe "#with_deliveries" do
    context "with false" do
      before do
        described_class.with_deliveries(false) do
          described_class.test_mail(recipient).deliver_now
        end
      end

      it_behaves_like "mail is not sent"
    end

    context "with true" do
      before do
        described_class.with_deliveries(true) do
          described_class.test_mail(recipient).deliver_now
        end
      end

      it_behaves_like "mail is sent"
    end

    context "with true but user is locked" do
      let(:recipient) { build_stubbed(:user, status: Principal.statuses[:locked]) }

      before do
        described_class.with_deliveries(true) do
          described_class.test_mail(recipient).deliver_now
        end
      end

      it_behaves_like "mail is not sent"
    end
  end

  describe "#test_mail" do
    let(:test_email) { "bob.bobbi@example.com" }
    let(:recipient) { build_stubbed(:user, firstname: "Bob", lastname: "Bobbi", mail: test_email) }

    before do
      described_class.test_mail(recipient).deliver_now
    end

    it_behaves_like "mail is sent" do
      it "has the expected subject" do
        expect(deliveries.first.subject)
          .to eql "OpenProject Test"
      end

      it "includes the url to the instance" do
        expect(deliveries.first.body.encoded)
          .to match Regexp.new("OpenProject URL: #{Setting.protocol}://#{Setting.host_name}")
      end
    end

    # the name method uses a format setting to determine how to concatenate first name
    # and last name whereby an unescaped comma will lead to have two email addresses
    # defined instead of one (['Bobbi', 'bob.bobbi@example.com'] vs. ['bob.bobbi@example.com'])
    context "with the user name setting prone to trip up email address separation",
            with_settings: { user_format: :lastname_coma_firstname } do
      it_behaves_like "mail is sent"
    end

    context "with the recipient being the system user" do
      let(:recipient) { User.system }

      it_behaves_like "mail is not sent"
    end
  end

  describe "#backup_ready" do
    before do
      described_class.backup_ready(recipient).deliver_now
    end

    it_behaves_like "mail is sent" do
      it "has the expected subject" do
        expect(deliveries.first.subject)
          .to eql I18n.t("mail_subject_backup_ready")
      end

      it "includes the url to the instance" do
        expect(deliveries.first.body.encoded)
          .to match Regexp.union(
            /Your requested backup is ready. You can download it here/,
            /#{Setting.protocol}:\/\/#{Setting.host_name}/
          )
      end
    end
  end

  describe "#wiki_page_added" do
    let(:wiki_page) { create(:wiki_page) }

    before do
      described_class.wiki_page_added(recipient, wiki_page).deliver_now
    end

    it_behaves_like "mail is sent"
  end

  describe "#wiki_page_updated" do
    let(:wiki_page) { create(:wiki_page) }
    let(:wiki_page_journal) { build_stubbed(:wiki_page_journal) }

    before do
      allow(wiki_page).to receive(:journals).and_return([wiki_page_journal])
      described_class.wiki_page_updated(recipient, wiki_page).deliver_now
    end

    it_behaves_like "mail is sent"

    it "links to the latest version diff page" do
      expect(deliveries.first.body.encoded).to include "diff/#{wiki_page.version}"
    end

    it "uses the author from the journal" do
      expect(deliveries.first.body.encoded).to include wiki_page_journal.user.name
    end
  end

  describe "#message_posted" do
    before do
      described_class.message_posted(recipient, message).deliver_now
    end

    context "for a message without a parent" do
      let(:message) do
        build_stubbed(:message).tap do |msg|
          allow(msg)
            .to receive(:project)
                  .and_return(msg.forum.project)
        end
      end

      it_behaves_like "mail is sent" do
        it "carries a message_id" do
          expect(deliveries.first.message_id)
            .to eql "op.message-#{message.id}.#{current_time.strftime('%Y%m%d%H%M%S')}.#{recipient.id}@doe.com"
        end

        it "references the message" do
          expect(deliveries.first.references)
            .to eql "op.message-#{message.id}@doe.com"
        end

        it "includes a link to the message" do
          expect(html_body)
            .to have_link(message.subject,
                          href: topic_url(message, host: Setting.host_name, r: message.id, anchor: "message-#{message.id}"))
        end
      end
    end

    context "for a message with a parent" do
      let(:parent) do
        build_stubbed(:message)
      end

      let(:message) do
        build_stubbed(:message, parent:).tap do |msg|
          allow(msg)
            .to receive(:project)
                  .and_return(msg.forum.project)
        end
      end

      it_behaves_like "mail is sent" do
        it "carries a message_id" do
          expect(deliveries.first.message_id)
            .to eql "op.message-#{message.id}.#{current_time.strftime('%Y%m%d%H%M%S')}.#{recipient.id}@doe.com"
        end

        it "references the message" do
          expect(deliveries.first.references)
            .to eql %W[op.message-#{parent.id}@doe.com
                       op.message-#{message.id}@doe.com]
        end
      end
    end
  end

  describe "#account_information" do
    let(:pwd) { "pAsswORd" }

    before do
      described_class.account_information(recipient, pwd).deliver_now
    end

    it_behaves_like "mail is sent" do
      it "includes the password" do
        expect(html_body)
          .to have_content(pwd)
      end
    end
  end

  describe "#incoming_email_error" do
    let(:logs) { ["info: foo", "error: bar"] }
    let(:recipient) { user }
    let(:current_time) { "2022-11-03 9:15".to_time }
    let(:mail_subject) { "New work package 42" }
    let(:message_id) { "000501c8d452$a95cd7e0$0a00a8c0@osiris" }
    let(:from) { "l.lustig@openproject.com" }
    let(:body) { "Project: demo-project" }

    let(:incoming_email) do
      {
        message_id:,
        from:,
        subject: mail_subject,
        quote: body,
        text: body
      }
    end

    let(:outgoing_email) { deliveries.first }

    before do
      described_class
        .incoming_email_error(user, incoming_email, logs)
        .deliver_now
    end

    it_behaves_like "mail is sent" do
      it "references the incoming email's subject in its own" do
        expect(outgoing_email.subject).to eql "Re: #{mail_subject}"
      end

      it "it's a reply to the incoming email" do
        expect(message_id).to include outgoing_email.in_reply_to
        expect(message_id).to include outgoing_email.references
      end

      it "contains the incoming email's quoted content" do
        expect(html_body).to include body
      end

      it "contains the date the mail was received" do
        expect(html_body).to include "11/03/2022 09:15 AM"
      end

      it "contains the email address from which the email was sent" do
        expect(html_body).to include from
      end

      it "contains the logs" do
        logs.each do |log|
          expect(html_body).to include log
        end
      end
    end
  end

  describe "#news_added" do
    let(:news) { build_stubbed(:news) }

    before do
      described_class.news_added(recipient, news).deliver_now
    end

    it_behaves_like "mail is sent" do
      it "carries a message_id" do
        expect(mail.message_id)
          .to eql "op.news-#{news.id}.#{current_time.strftime('%Y%m%d%H%M%S')}.#{recipient.id}@doe.com"
      end

      it "references the news" do
        expect(deliveries.first.references)
          .to eql "op.news-#{news.id}@doe.com"
      end
    end
  end

  describe "#news_comment_added" do
    let(:news) { build_stubbed(:news) }
    let(:comment) { build_stubbed(:comment, commented: news) }

    before do
      described_class.news_comment_added(recipient, comment).deliver_now
    end

    it_behaves_like "mail is sent" do
      it "references the news and the comment" do
        expect(deliveries.first.references)
          .to eql %W[op.news-#{news.id}@doe.com
                     op.comment-#{comment.id}@doe.com]
      end
    end
  end

  describe "#password_lost" do
    let(:token) { build_stubbed(:recovery_token) }
    let(:recipient) { token.user }

    before do
      described_class.password_lost(token).deliver_now
    end

    it_behaves_like "mail is sent" do
      it "includes a link to reset" do
        url = account_lost_password_url(host: Setting.host_name, token: token.value)

        expect(html_body)
          .to have_link(url,
                        href: url)
      end
    end
  end

  describe "#user_signed_up" do
    let(:token) { build_stubbed(:invitation_token) }
    let(:recipient) { token.user }

    before do
      described_class.user_signed_up(token).deliver_now
    end

    it_behaves_like "mail is sent" do
      it "includes a link to activate" do
        url = account_activate_url(host: Setting.host_name, token: token.value)

        expect(html_body)
          .to have_link(url,
                        href: url)
      end
    end
  end

  describe "localization" do
    context "with the user having a language configured",
            with_settings: { available_languages: %w[en de],
                             default_language: "en",
                             emails_header: {
                               "de" => "deutscher header",
                               "en" => "english header"
                             } } do
      let(:recipient) do
        build_stubbed(:user, language: "de")
      end

      before do
        described_class.account_information(recipient, "pwd").deliver_now
      end

      it "uses the recipients language" do
        expect(ActionMailer::Base.deliveries.last.body.parts.detect { |p| p.content_type.include? "text/html" }.body.encoded)
          .to include I18n.t(:mail_body_account_information, locale: :de)
      end

      it "does not alter I18n.locale" do
        expect(I18n.locale)
          .to be :en
      end

      it "include the user language header" do
        expect(ActionMailer::Base.deliveries.last.body.parts.detect { |p| p.content_type.include? "text/html" }.body.encoded)
          .to include "deutscher header"
      end
    end

    context "with the user having no language configured",
            with_settings: { available_languages: %w[en de],
                             default_language: "en",
                             emails_header: {
                               "de" => "deutscher header",
                               "en" => "english header"
                             } } do
      let(:recipient) do
        build_stubbed(:user, language: "")
      end

      before do
        I18n.locale = :de

        described_class.account_information(recipient, "pwd").deliver_now
      end

      it "uses the default language" do
        expect(ActionMailer::Base.deliveries.last.body.parts.detect { |p| p.content_type.include? "text/html" }.body.encoded)
          .to include I18n.t(:mail_body_account_information, locale: :en)
      end

      it "include the default language header" do
        expect(ActionMailer::Base.deliveries.last.body.parts.detect { |p| p.content_type.include? "text/html" }.body.encoded)
          .to include "english header"
      end

      it "does not alter I18n.locale" do
        expect(I18n.locale)
          .to be :de
      end
    end
  end
end
