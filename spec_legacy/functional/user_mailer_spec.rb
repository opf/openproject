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

require_relative '../legacy_spec_helper'

describe UserMailer, type: :mailer do
  include ::Rails::Dom::Testing::Assertions::SelectorAssertions

  before do
    Setting.mail_from = 'john@doe.com'
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'http'
    Setting.plain_text_mail = '0'
    Setting.default_language = 'en'

    User.delete_all
    WorkPackage.delete_all
    Project.delete_all
    ::Type.delete_all
  end

  it 'should test mail sends a simple greeting' do
    user = FactoryGirl.create(:admin, mail: 'foo@bar.de')

    FactoryGirl.create(:user_preference, user: user, others: { no_self_notified: false })

    mail = UserMailer.test_mail(user)
    assert mail.deliver_now

    assert_equal 1, ActionMailer::Base.deliveries.size

    assert_equal 'OpenProject Test', mail.subject
    assert_equal ['foo@bar.de'], mail.to
    assert_equal ['john@doe.com'], mail.from
    assert_match /OpenProject URL/, mail.body.encoded
  end

  it 'should generated links in emails' do
    Setting.default_language = 'en'
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'https'

    project, user, related_issue, issue, changeset, attachment, journal = setup_complex_issue_update

    assert UserMailer.work_package_updated(user, journal).deliver_now
    assert last_email

    assert_select_email do
      # link to the main ticket
      assert_select 'a[href=?]',
                    "https://mydomain.foo/work_packages/#{issue.id}",
                    text: "My Type ##{issue.id}: My awesome Ticket"
      # link to a description diff
      assert_select 'li', text: /Description changed/
      assert_select 'li>a[href=?]',
                    "https://mydomain.foo/journals/#{journal.id}/diff/description",
                    text: 'Details'
      # link to a referenced ticket
      assert_select 'a[href=?][title=?]',
                    "https://mydomain.foo/work_packages/#{related_issue.id}",
                    "My related Ticket (#{related_issue.status})",
                    text: "##{related_issue.id}"
      # link to a changeset
      if changeset
        assert_select 'a[href=?][title=?]',
                      url_for(controller: 'repositories',
                              action: 'revision',
                              project_id: project,
                              rev: changeset.revision),
                      'This commit fixes #1, #2 and references #1 and #3',
                      text: "r#{changeset.revision}"
      end
      # link to an attachment
      assert_select 'a[href=?]',
                    "https://mydomain.foo/attachments/#{attachment.id}/#{attachment.filename}",
                    text: "#{attachment.filename}"
    end
  end

  it 'should generated links with prefix' do
    Setting.default_language = 'en'
    Setting.host_name = 'mydomain.foo/rdm'
    Setting.protocol = 'http'

    project, user, related_issue, issue, changeset, attachment, journal = setup_complex_issue_update

    assert UserMailer.work_package_updated(user, journal).deliver_now
    assert last_email

    assert_select_email do
      # link to the main ticket
      assert_select 'a[href=?]',
                    "http://mydomain.foo/rdm/work_packages/#{issue.id}",
                    text: "My Type ##{issue.id}: My awesome Ticket"
      # link to a description diff
      assert_select 'li', text: /Description changed/
      assert_select 'li>a[href=?]',
                    "http://mydomain.foo/rdm/journals/#{journal.id}/diff/description",
                    text: 'Details'
      # link to a referenced ticket
      assert_select 'a[href=?][title=?]',
                    "http://mydomain.foo/rdm/work_packages/#{related_issue.id}",
                    "My related Ticket (#{related_issue.status})",
                    text: "##{related_issue.id}"
      # link to a changeset
      if changeset
        assert_select 'a[href=?][title=?]',
                      url_for(controller: 'repositories',
                              action: 'revision',
                              project_id: project,
                              rev: changeset.revision),
                      'This commit fixes #1, #2 and references #1 and #3',
                      text: "r#{changeset.revision}"
      end
      # link to an attachment
      assert_select 'a[href=?]',
                    "http://mydomain.foo/rdm/attachments/#{attachment.id}/#{attachment.filename}",
                    text: "#{attachment.filename}"
    end
  end

  it 'should generated links with prefix and no relative url root' do
    begin
      Setting.default_language = 'en'
      relative_url_root = OpenProject::Configuration['rails_relative_url_root']
      Setting.host_name = 'mydomain.foo/rdm'
      Setting.protocol = 'http'
      OpenProject::Configuration['rails_relative_url_root'] = nil

      project, user, related_issue, issue, changeset, attachment, journal = setup_complex_issue_update

      assert UserMailer.work_package_updated(user, journal).deliver_now
      assert last_email

      assert_select_email do
        # link to the main ticket
        assert_select 'a[href=?]',
                      "http://mydomain.foo/rdm/work_packages/#{issue.id}",
                      text: "My Type ##{issue.id}: My awesome Ticket"
        # link to a description diff
        assert_select 'li', text: /Description changed/
        assert_select 'li>a[href=?]',
                      "http://mydomain.foo/rdm/journals/#{journal.id}/diff/description",
                      text: 'Details'
        # link to a referenced ticket
        assert_select 'a[href=?][title=?]',
                      "http://mydomain.foo/rdm/work_packages/#{related_issue.id}",
                      "My related Ticket (#{related_issue.status})",
                      text: "##{related_issue.id}"
        # link to a changeset
        if changeset
          assert_select 'a[href=?][title=?]',
                        url_for(controller: 'repositories',
                                action: 'revision',
                                project_id: project,
                                rev: changeset.revision),
                        'This commit fixes #1, #2 and references #1 and #3',
                        text: "r#{changeset.revision}"
        end
        # link to an attachment
        assert_select 'a[href=?]',
                      "http://mydomain.foo/rdm/attachments/#{attachment.id}/#{attachment.filename}",
                      text: "#{attachment.filename}"
      end
    ensure
      # restore it
      OpenProject::Configuration['rails_relative_url_root'] = relative_url_root
    end
  end

  it 'should email headers' do
    user  = FactoryGirl.create(:user)
    issue = FactoryGirl.create(:work_package)
    mail = UserMailer.work_package_added(user, issue.journals.first, user)
    assert mail.deliver_now
    refute_nil mail
    assert_equal 'bulk', mail.header['Precedence'].to_s
    assert_equal 'auto-generated', mail.header['Auto-Submitted'].to_s
  end

  it 'sends plain text mail' do
    Setting.plain_text_mail = 1
    user  = FactoryGirl.create(:user)
    FactoryGirl.create(:user_preference, user: user, others: { no_self_notified: false })
    issue = FactoryGirl.create(:work_package)
    UserMailer.work_package_added(user, issue.journals.first, user).deliver_now
    mail = ActionMailer::Base.deliveries.last
    assert_match /text\/plain/, mail.content_type
    assert_equal 0, mail.parts.size
    assert !mail.encoded.include?('href')
  end

  it 'sends html mail' do
    Setting.plain_text_mail = 0
    user  = FactoryGirl.create(:user)
    FactoryGirl.create(:user_preference, user: user, others: { no_self_notified: false })
    issue = FactoryGirl.create(:work_package)
    UserMailer.work_package_added(user, issue.journals.first, user).deliver_now
    mail = ActionMailer::Base.deliveries.last
    assert_match /multipart\/alternative/, mail.content_type
    assert_equal 2, mail.parts.size
    assert mail.encoded.include?('href')
  end

  context 'with mail_from set', with_settings: { mail_from: 'Redmine app <redmine@example.net>' } do
    it 'should mail from with phrase' do
      user  = FactoryGirl.create(:user)
      FactoryGirl.create(:user_preference, user: user, others: { no_self_notified: false })
      UserMailer.test_mail(user).deliver_now
      mail = ActionMailer::Base.deliveries.last
      refute_nil mail
      assert_equal 'Redmine app <redmine@example.net>', mail.header['From'].to_s
    end
  end

  it 'should not send email without recipient' do
    user  = FactoryGirl.create(:user)
    news  = FactoryGirl.create(:news)

    # notify him
    user.pref[:no_self_notified] = false
    user.pref.save
    ActionMailer::Base.deliveries.clear
    UserMailer.news_added(user, news, user).deliver_now
    assert_equal 1, last_email.to.size

    # nobody to notify
    user.pref[:no_self_notified] = true
    user.pref.save
    ActionMailer::Base.deliveries.clear
    UserMailer.news_added(user, news, user).deliver_now
    assert ActionMailer::Base.deliveries.empty?
  end

  it 'should issue add message id' do
    user  = FactoryGirl.create(:user)
    issue = FactoryGirl.create(:work_package)
    mail = UserMailer.work_package_added(user, issue.journals.first, user)
    mail.deliver_now
    refute_nil mail
    assert_equal UserMailer.generate_message_id(issue, user), mail.message_id
    assert_nil mail.references
  end

  it 'should work package updated message id' do
    user  = FactoryGirl.create(:user)
    issue = FactoryGirl.create(:work_package)
    journal = issue.journals.first
    UserMailer.work_package_updated(user, journal).deliver_now
    mail = ActionMailer::Base.deliveries.last
    refute_nil mail
    assert_equal UserMailer.generate_message_id(journal, user), mail.message_id
    assert_match mail.references, UserMailer.generate_message_id(journal.journable, user)
  end

  it 'should message posted message id' do
    user    = FactoryGirl.create(:user)
    FactoryGirl.create(:user_preference, user: user, others: { no_self_notified: false })
    message = FactoryGirl.create(:message)
    UserMailer.message_posted(user, message, user).deliver_now
    mail = ActionMailer::Base.deliveries.last
    refute_nil mail
    assert_equal UserMailer.generate_message_id(message, user), mail.message_id
    assert_nil mail.references
    assert_select_email do
      # link to the message
      assert_select 'a[href*=?]', "#{Setting.protocol}://#{Setting.host_name}/topics/#{message.id}", text: message.subject
    end
  end

  it 'should reply posted message id' do
    user    = FactoryGirl.create(:user)
    FactoryGirl.create(:user_preference, user: user, others: { no_self_notified: false })
    parent  = FactoryGirl.create(:message)
    message = FactoryGirl.create(:message, parent: parent)
    UserMailer.message_posted(user, message, user).deliver_now
    mail = ActionMailer::Base.deliveries.last
    refute_nil mail
    assert_equal UserMailer.generate_message_id(message, user), mail.message_id
    assert_match mail.references, UserMailer.generate_message_id(parent, user)
    assert_select_email do
      # link to the reply
      assert_select 'a[href=?]', "#{Setting.protocol}://#{Setting.host_name}/topics/#{message.root.id}?r=#{message.id}#message-#{message.id}", text: message.subject
    end
  end

  context '#issue_add',
          with_settings: { available_languages: ['en', 'de'], default_language: 'de' } do
    it 'should change mail language depending on recipient language' do
      issue = FactoryGirl.create(:work_package)
      user  = FactoryGirl.create(:user, mail: 'foo@bar.de', language: 'de')
      FactoryGirl.create(:user_preference, user: user, others: { no_self_notified: false })

      I18n.locale = 'en'
      assert UserMailer.work_package_added(user, issue.journals.first, user).deliver_now
      assert_equal 1, ActionMailer::Base.deliveries.size
      mail = last_email
      assert_equal ['foo@bar.de'], mail.to
      assert mail.body.encoded.include?('erstellt')
      assert !mail.body.encoded.include?('reported')
      assert_equal :en, I18n.locale
    end

    it 'should falls back to default language if user has no language' do
      # 1. user's language
      # 2. Setting.default_language
      # 3. I18n.default_locale
      issue = FactoryGirl.create(:work_package)
      user  = FactoryGirl.create(:user, mail: 'foo@bar.de', language: '') # (auto)
      FactoryGirl.create(:user_preference, user: user, others: { no_self_notified: false })

      I18n.locale = 'de'
      assert UserMailer.work_package_added(user, issue.journals.first, user).deliver_now
      assert_equal 1, ActionMailer::Base.deliveries.size
      mail = last_email
      assert_equal ['foo@bar.de'], mail.to
      assert !mail.body.encoded.include?('reported')
      assert mail.body.encoded.include?('erstellt')
      assert_equal :de, I18n.locale
    end
  end

  it 'should news added' do
    user = FactoryGirl.create(:user)
    news = FactoryGirl.create(:news)
    assert UserMailer.news_added(user, news, user).deliver_now
  end

  it 'should news comment added' do
    user    = FactoryGirl.create(:user)
    news    = FactoryGirl.create(:news)
    comment = FactoryGirl.create(:comment, commented: news)
    assert UserMailer.news_comment_added(user, comment, user).deliver_now
  end

  it 'should message posted' do
    user    = FactoryGirl.create(:user)
    message = FactoryGirl.create(:message)
    assert UserMailer.message_posted(user, message, user).deliver_now
  end

  it 'should account information' do
    user = FactoryGirl.create(:user)
    assert UserMailer.account_information(user, 'pAsswORd').deliver_now
  end

  it 'should lost password' do
    user  = FactoryGirl.create(:user)
    token = FactoryGirl.create(:token, user: user)
    assert UserMailer.password_lost(token).deliver_now
  end

  it 'should register' do
    user  = FactoryGirl.create(:user)
    token = FactoryGirl.create(:token, user: user)
    Setting.host_name = 'redmine.foo'
    Setting.protocol = 'https'

    mail = UserMailer.user_signed_up(token)
    assert mail.deliver_now
    assert mail.body.encoded.include?("https://redmine.foo/account/activate?token=#{token.value}")
  end

  it 'should reminders' do
    user  = FactoryGirl.create(:user, mail: 'foo@bar.de')
    issue = FactoryGirl.create(:work_package, due_date: Date.tomorrow, assigned_to: user, subject: 'some issue')

    DueIssuesReminder.new(42).remind_users
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries.last
    assert mail.to.include?('foo@bar.de')
    assert mail.body.encoded.include?("#{issue.project.name} - #{issue.type.name} ##{issue.id}: some issue")
    assert_equal '1 work package(s) due in the next 42 days', mail.subject
  end

  it 'should reminders for users' do
    user1  = FactoryGirl.create(:user, mail: 'foo1@bar.de')
    user2  = FactoryGirl.create(:user, mail: 'foo2@bar.de')
    issue = FactoryGirl.create(:work_package, due_date: Date.tomorrow, assigned_to: user1, subject: 'some issue')

    DueIssuesReminder.new(42, nil, nil, [user2.id]).remind_users
    assert_equal 0, ActionMailer::Base.deliveries.size

    DueIssuesReminder.new(42, nil, nil, [user1.id]).remind_users
    assert_equal 1, ActionMailer::Base.deliveries.size

    mail = ActionMailer::Base.deliveries.last
    assert mail.to.include?('foo1@bar.de')
    assert mail.body.encoded.include?("#{issue.project.name} - #{issue.type.name} ##{issue.id}: some issue")
    assert_equal '1 work package(s) due in the next 42 days', mail.subject
  end

  context 'with locale settings',
          with_settings: { available_languages: ['en', 'de'], default_language: 'de' } do
    it 'should mailer should not change locale' do
      # Set current language to english
      I18n.locale = :en
      # Send an email to a german user
      user = FactoryGirl.create(:user, language: 'de')
      UserMailer.account_activated(user).deliver_now
      mail = ActionMailer::Base.deliveries.last
      assert mail.body.encoded.include?('aktiviert')
      assert_equal :en, I18n.locale
    end
  end

  it 'should with deliveries off' do
    user = FactoryGirl.create(:user)
    UserMailer.with_deliveries(false) do
      UserMailer.test_mail(user).deliver_now
    end
    assert ActionMailer::Base.deliveries.empty?
    # should restore perform_deliveries
    assert ActionMailer::Base.perform_deliveries
  end

  context 'layout',
          with_settings: {
            available_languages: [:en, :de],
            localized_emails_header: 'deutscher header'
          } do
    it 'should include the emails_header depeding on the locale' do
      user = FactoryGirl.create(:user, language: :de)
      assert UserMailer.test_mail(user).deliver_now
      mail = ActionMailer::Base.deliveries.last
      assert mail.body.encoded.include?('deutscher header')
    end
  end

  private

  def last_email
    mail = ActionMailer::Base.deliveries.last
    refute_nil mail
    mail
  end

  def setup_complex_issue_update
    project = FactoryGirl.create(:valid_project)
    user    = FactoryGirl.create(:admin, member_in_project: project)
    type = FactoryGirl.create(:type, name: 'My Type')
    project.types << type
    project.save

    related_issue = FactoryGirl.create(:work_package,
                                       subject: 'My related Ticket',
                                       type: type,
                                       project: project)

    issue   = FactoryGirl.create(:work_package,
                                 subject: 'My awesome Ticket',
                                 type: type,
                                 project: project,
                                 description: 'nothing here yet')

    # now change the issue, to get a nice journal
    issue.description = "This is related to issue ##{related_issue.id}\n"

    repository = FactoryGirl.create(:repository_subversion,
                                     project: project)

    changeset = FactoryGirl.create :changeset,
                         repository: repository,
                         comments: 'This commit fixes #1, #2 and references #1 and #3'

    issue.description += " A reference to a changeset r#{changeset.revision}\n" if changeset

    attachment = FactoryGirl.create(:attachment,
                                    container: issue,
                                    author: issue.author)

    issue.description += " A reference to an attachment attachment:#{attachment.filename}"

    assert issue.save
    issue.reload
    journal = issue.journals.last

    ActionMailer::Base.deliveries = [] # remove issue-created mails

    [project, user, related_issue, issue, changeset, attachment, journal]
  end

  def url_for(options)
    options.merge!(host: Setting.host_name, protocol: Setting.protocol)
    Rails.application.routes.url_helpers.url_for options
  end
end
