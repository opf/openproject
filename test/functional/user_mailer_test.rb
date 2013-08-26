#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../test_helper', __FILE__)

class UserMailerTest < ActionMailer::TestCase
  include ActionDispatch::Assertions::SelectorAssertions

  def setup
    super
    Setting.mail_from = 'john@doe.com'
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'http'
    Setting.plain_text_mail = '0'
    Setting.default_language = 'en'

    User.delete_all
    Issue.delete_all
    Project.delete_all
    Type.delete_all
    ActionMailer::Base.deliveries.clear
  end

  def test_test_mail_sends_a_simple_greeting
    user = FactoryGirl.create(:user, :mail => 'foo@bar.de')

    mail = UserMailer.test_mail(user)
    assert mail.deliver

    assert_equal 1, ActionMailer::Base.deliveries.size

    assert_equal 'OpenProject Test', mail.subject
    assert_equal ['foo@bar.de'], mail.to
    assert_equal ['john@doe.com'], mail.from
    assert_match /OpenProject URL/, mail.body.encoded
  end

  def test_issue_add
    user  = FactoryGirl.create(:user, :mail => 'foo@bar.de')
    issue = FactoryGirl.create(:issue, :subject => 'some issue title')

    # creating an issue actually sends an email, ohoh
    ActionMailer::Base.deliveries.clear

    mail = UserMailer.issue_added(user, issue)
    assert mail.deliver

    assert_equal 1, ActionMailer::Base.deliveries.size

    assert_match /some issue title/, mail.subject
    assert_equal ['foo@bar.de'], mail.to
    assert_equal ['john@doe.com'], mail.from
    assert_match /has been reported/, mail.body.encoded
  end

  def test_generated_links_in_emails
    Setting.default_language = 'en'
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'https'
    User.current = FactoryGirl.create(:admin)

    project, user, related_issue, issue, changeset, attachment, journal = setup_complex_issue_update

    assert UserMailer.issue_updated(user, journal).deliver
    assert last_email

    assert_select_email do
      # link to the main ticket
      assert_select 'a[href=?]',
                    "https://mydomain.foo/issues/#{issue.id}",
                    :text => "My Type ##{issue.id}: My awesome Ticket"
      # link to a description diff
      assert_select 'li', :text => /Description changed/
      assert_select 'li>a[href=?]',
                    "https://mydomain.foo/journals/#{journal.id}/diff/description",
                    :text => "Details"
      # link to a referenced ticket
      assert_select 'a[href=?][title=?]',
                    "https://mydomain.foo/work_packages/#{related_issue.id}",
                    "My related Ticket (#{related_issue.status})",
                    :text => "##{related_issue.id}"
      # link to a changeset
      assert_select 'a[href=?][title=?]',
                    "https://mydomain.foo/projects/#{project.identifier}/repository/revisions/#{changeset.revision}",
                    'This commit fixes #1, #2 and references #1 and #3',
                    :text => "r#{changeset.revision}"
      # link to an attachment
      assert_select 'a[href=?]',
                    "https://mydomain.foo/attachments/#{attachment.id}/download",
                    :text => "#{attachment.filename}"
    end
  end

  def test_generated_links_with_prefix
    Setting.default_language = 'en'
    Setting.host_name = 'mydomain.foo/rdm'
    Setting.protocol = 'http'
    User.current = FactoryGirl.create(:admin)

    project, user, related_issue, issue, changeset, attachment, journal = setup_complex_issue_update

    assert UserMailer.issue_updated(user, journal).deliver
    assert last_email

    assert_select_email do
      # link to the main ticket
      assert_select 'a[href=?]',
                    "http://mydomain.foo/rdm/issues/#{issue.id}",
                    :text => "My Type ##{issue.id}: My awesome Ticket"
      # link to a description diff
      assert_select 'li', :text => /Description changed/
      assert_select 'li>a[href=?]',
                    "http://mydomain.foo/rdm/journals/#{journal.id}/diff/description",
                    :text => "Details"
      # link to a referenced ticket
      assert_select 'a[href=?][title=?]',
                    "http://mydomain.foo/rdm/work_packages/#{related_issue.id}",
                    "My related Ticket (#{related_issue.status})",
                    :text => "##{related_issue.id}"
      # link to a changeset
      assert_select 'a[href=?][title=?]',
                    "http://mydomain.foo/rdm/projects/#{project.identifier}/repository/revisions/#{changeset.revision}",
                    'This commit fixes #1, #2 and references #1 and #3',
                    :text => "r#{changeset.revision}"
      # link to an attachment
      assert_select 'a[href=?]',
                    "http://mydomain.foo/rdm/attachments/#{attachment.id}/download",
                    :text => "#{attachment.filename}"
    end
  end

  def test_generated_links_with_prefix_and_no_relative_url_root
    Setting.default_language = 'en'
    relative_url_root = Redmine::Utils.relative_url_root
    Setting.host_name = 'mydomain.foo/rdm'
    Setting.protocol = 'http'
    Redmine::Utils.relative_url_root = nil

    User.current = FactoryGirl.create(:admin)

    project, user, related_issue, issue, changeset, attachment, journal = setup_complex_issue_update

    assert UserMailer.issue_updated(user, journal).deliver
    assert last_email

    assert_select_email do
      # link to the main ticket
      assert_select 'a[href=?]',
                    "http://mydomain.foo/rdm/issues/#{issue.id}",
                    :text => "My Type ##{issue.id}: My awesome Ticket"
      # link to a description diff
      assert_select 'li', :text => /Description changed/
      assert_select 'li>a[href=?]',
                    "http://mydomain.foo/rdm/journals/#{journal.id}/diff/description",
                    :text => "Details"
      # link to a referenced ticket
      assert_select 'a[href=?][title=?]',
                    "http://mydomain.foo/rdm/work_packages/#{related_issue.id}",
                    "My related Ticket (#{related_issue.status})",
                    :text => "##{related_issue.id}"
      # link to a changeset
      assert_select 'a[href=?][title=?]',
                    "http://mydomain.foo/rdm/projects/#{project.identifier}/repository/revisions/#{changeset.revision}",
                    'This commit fixes #1, #2 and references #1 and #3',
                    :text => "r#{changeset.revision}"
      # link to an attachment
      assert_select 'a[href=?]',
                    "http://mydomain.foo/rdm/attachments/#{attachment.id}/download",
                    :text => "#{attachment.filename}"
    end
  ensure
    # restore it
    Redmine::Utils.relative_url_root = relative_url_root
  end

  def test_email_headers
    user  = FactoryGirl.create(:user)
    issue = FactoryGirl.create(:issue)
    mail = UserMailer.issue_added(user, issue)
    assert mail.deliver
    assert_not_nil mail
    assert_equal 'bulk', mail.header['Precedence'].to_s
    assert_equal 'auto-generated', mail.header['Auto-Submitted'].to_s
  end

  def test_plain_text_mail
    Setting.plain_text_mail = 1
    user  = FactoryGirl.create(:user)
    issue = FactoryGirl.create(:issue)
    UserMailer.issue_added(user, issue).deliver
    mail = ActionMailer::Base.deliveries.last
    assert_match /text\/plain/, mail.content_type
    assert_equal 0, mail.parts.size
    assert !mail.encoded.include?('href')
  end

  def test_html_mail
    Setting.plain_text_mail = 0
    user  = FactoryGirl.create(:user)
    issue = FactoryGirl.create(:issue)
    UserMailer.issue_added(user, issue).deliver
    mail = ActionMailer::Base.deliveries.last
    assert_match /multipart\/alternative/, mail.content_type
    assert_equal 2, mail.parts.size
    assert mail.encoded.include?('href')
  end

  def test_mail_from_with_phrase
    user  = FactoryGirl.create(:user)
    with_settings :mail_from => 'Redmine app <redmine@example.net>' do
      UserMailer.test_mail(user).deliver
    end
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal 'Redmine app <redmine@example.net>', mail.header['From'].to_s
  end

  def test_should_not_send_email_without_recipient
    user  = FactoryGirl.create(:user)
    news  = FactoryGirl.create(:news)

    # notify him
    user.pref[:no_self_notified] = false
    user.pref.save
    User.current = user
    ActionMailer::Base.deliveries.clear
    UserMailer.news_added(user, news).deliver
    assert_equal 1, last_email.to.size

    # nobody to notify
    user.pref[:no_self_notified] = true
    user.pref.save
    User.current = user
    ActionMailer::Base.deliveries.clear
    UserMailer.news_added(user, news).deliver
    assert ActionMailer::Base.deliveries.empty?
  end

  def test_issue_add_message_id
    user  = FactoryGirl.create(:user)
    issue = FactoryGirl.create(:issue)
    mail = UserMailer.issue_added(user, issue)
    mail.deliver
    assert_not_nil mail
    assert_equal UserMailer.generate_message_id(issue), mail.message_id
    assert_nil mail.references
  end

  def test_issue_updated_message_id
    user  = FactoryGirl.create(:user)
    issue = FactoryGirl.create(:issue)
    journal = issue.journals.first
    UserMailer.issue_updated(user, journal).deliver
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal UserMailer.generate_message_id(journal), mail.message_id
    assert_match mail.references, UserMailer.generate_message_id(journal.journable)
  end

  def test_message_posted_message_id
    user    = FactoryGirl.create(:user)
    message = FactoryGirl.create(:message)
    UserMailer.message_posted(user, message).deliver
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal UserMailer.generate_message_id(message), mail.message_id
    assert_nil mail.references
    assert_select_email do
      # link to the message
      assert_select "a[href*=?]", "#{Setting.protocol}://#{Setting.host_name}/topics/#{message.id}", :text => message.subject
    end
  end

  def test_reply_posted_message_id
    user    = FactoryGirl.create(:user)
    parent  = FactoryGirl.create(:message)
    message = FactoryGirl.create(:message, :parent => parent)
    UserMailer.message_posted(user, message).deliver
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal UserMailer.generate_message_id(message), mail.message_id
    assert_match mail.references, UserMailer.generate_message_id(parent)
    assert_select_email do
      # link to the reply
      assert_select "a[href=?]", "#{Setting.protocol}://#{Setting.host_name}/topics/#{message.root.id}?r=#{message.id}#message-#{message.id}", :text => message.subject
    end
  end

  context("#issue_add") do
    should "send one email per recipient" do
      user  = FactoryGirl.create(:user, :mail => 'foo@bar.de')
      issue = FactoryGirl.create(:issue)
      ActionMailer::Base.deliveries.clear
      assert UserMailer.issue_added(user, issue).deliver
      assert_equal 1, ActionMailer::Base.deliveries.size
      assert_equal ['foo@bar.de'], last_email.to
    end

    should "change mail language depending on recipient language" do
      issue = FactoryGirl.create(:issue)
      user  = FactoryGirl.create(:user, :mail => 'foo@bar.de', :language => 'de')
      ActionMailer::Base.deliveries.clear
      with_settings :available_languages => ['en', 'de'] do
        I18n.locale = 'en'
        assert UserMailer.issue_added(user, issue).deliver
        assert_equal 1, ActionMailer::Base.deliveries.size
        mail = last_email
        assert_equal ['foo@bar.de'], mail.to
        assert mail.body.encoded.include?('erstellt')
        assert !mail.body.encoded.include?('reported')
        assert_equal :en, I18n.locale
      end
    end

    should "falls back to default language if user has no language" do
      # 1. user's language
      # 2. Setting.default_language
      # 3. I18n.default_locale
      issue = FactoryGirl.create(:issue)
      user  = FactoryGirl.create(:user, :mail => 'foo@bar.de', :language => '') # (auto)
      ActionMailer::Base.deliveries.clear
      with_settings :available_languages => ['en', 'de'],
                    :default_language => 'de' do
        I18n.locale = 'de'
        assert UserMailer.issue_added(user, issue).deliver
        assert_equal 1, ActionMailer::Base.deliveries.size
        mail = last_email
        assert_equal ['foo@bar.de'], mail.to
        assert !mail.body.encoded.include?('reported')
        assert mail.body.encoded.include?('erstellt')
        assert_equal :de, I18n.locale
      end
    end
  end

  def test_issue_add
    user  = FactoryGirl.create(:user)
    issue = FactoryGirl.create(:issue)
    assert UserMailer.issue_added(user, issue).deliver
  end

  def test_issue_updated
    user    = FactoryGirl.create(:user)
    issue   = FactoryGirl.create(:issue)
    journal = issue.journals.first
    assert UserMailer.issue_updated(user, journal).deliver
  end

  def test_news_added
    user = FactoryGirl.create(:user)
    news = FactoryGirl.create(:news)
    assert UserMailer.news_added(user, news).deliver
  end

  def test_news_comment_added
    user    = FactoryGirl.create(:user)
    news    = FactoryGirl.create(:news)
    comment = FactoryGirl.create(:comment, :commented => news)
    assert UserMailer.news_comment_added(user, comment).deliver
  end

  def test_message_posted
    user    = FactoryGirl.create(:user)
    message = FactoryGirl.create(:message)
    assert UserMailer.message_posted(user, message).deliver
  end

  def test_wiki_content_added
    user         = FactoryGirl.create(:user)
    wiki_content = FactoryGirl.create(:wiki_content)
    assert UserMailer.wiki_content_added(user, wiki_content).deliver
  end

  def test_wiki_content_updated
    user         = FactoryGirl.create(:user)
    wiki_content = FactoryGirl.create(:wiki_content)
    assert UserMailer.wiki_content_updated(user, wiki_content).deliver
  end

  def test_account_information
    user = FactoryGirl.create(:user)
    assert UserMailer.account_information(user, 'pAsswORd').deliver
  end

  def test_lost_password
    user  = FactoryGirl.create(:user)
    token = FactoryGirl.create(:token, :user => user)
    assert UserMailer.password_lost(token).deliver
  end

  def test_register
    user  = FactoryGirl.create(:user)
    token = FactoryGirl.create(:token, :user => user)
    Setting.host_name = 'redmine.foo'
    Setting.protocol = 'https'

    mail = UserMailer.user_signed_up(token)
    assert mail.deliver
    assert mail.body.encoded.include?("https://redmine.foo/account/activate?token=#{token.value}")
  end

  def test_reminders
    user  = FactoryGirl.create(:user, :mail => 'foo@bar.de')
    issue = FactoryGirl.create(:issue, :due_date => Date.tomorrow, :assigned_to => user, :subject => 'some issue')
    ActionMailer::Base.deliveries.clear
    DueIssuesReminder.new(42).remind_users
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries.last
    assert mail.to.include?('foo@bar.de')
    assert mail.body.encoded.include?("#{issue.project.name} - #{issue.type.name} ##{issue.id}: some issue")
    assert_equal '1 work package(s) due in the next 42 days', mail.subject
  end

  def test_reminders_for_users
    user1  = FactoryGirl.create(:user, :mail => 'foo1@bar.de')
    user2  = FactoryGirl.create(:user, :mail => 'foo2@bar.de')
    issue = FactoryGirl.create(:issue, :due_date => Date.tomorrow, :assigned_to => user1, :subject => 'some issue')
    ActionMailer::Base.deliveries.clear

    DueIssuesReminder.new(42, nil, nil, [user2.id]).remind_users
    assert_equal 0, ActionMailer::Base.deliveries.size

    DueIssuesReminder.new(42, nil, nil, [user1.id]).remind_users
    assert_equal 1, ActionMailer::Base.deliveries.size

    mail = ActionMailer::Base.deliveries.last
    assert mail.to.include?('foo1@bar.de')
    assert mail.body.encoded.include?("#{issue.project.name} - #{issue.type.name} ##{issue.id}: some issue")
    assert_equal '1 work package(s) due in the next 42 days', mail.subject
  end

  def test_mailer_should_not_change_locale
    with_settings :available_languages => ['en', 'de'],
                  :default_language    => 'en' do
      # Set current language to english
      I18n.locale = :en
      # Send an email to a german user
      user = FactoryGirl.create(:user, :language => 'de')
      UserMailer.account_activated(user).deliver
      mail = ActionMailer::Base.deliveries.last
      assert mail.body.encoded.include?('aktiviert')
      assert_equal :en, I18n.locale
    end
  end

  def test_with_deliveries_off
    user = FactoryGirl.create(:user)
    UserMailer.with_deliveries(false) do
      UserMailer.test_mail(user).deliver
    end
    assert ActionMailer::Base.deliveries.empty?
    # should restore perform_deliveries
    assert ActionMailer::Base.perform_deliveries
  end

  context "layout" do
    should "include the emails_header depeding on the locale" do
      with_settings :available_languages => [:en, :de],
                    :emails_header => { "de" => "deutscher header",
                                        "en" => "english header" } do
        user = FactoryGirl.create(:user, :language => :en)
        assert UserMailer.test_mail(user).deliver
        mail = ActionMailer::Base.deliveries.last
        assert mail.body.encoded.include?('english header')
        user.language = :de
        assert UserMailer.test_mail(user).deliver
        mail = ActionMailer::Base.deliveries.last
        assert mail.body.encoded.include?('deutscher header')
      end
    end
  end

private

  def last_email
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    mail
  end

  def setup_complex_issue_update
    project = FactoryGirl.create(:valid_project)
    user    = FactoryGirl.create(:user, :member_in_project => project)
    type = FactoryGirl.create(:type, :name => 'My Type')
    project.types << type
    project.save

    related_issue = FactoryGirl.create(:issue,
        :subject => 'My related Ticket',
        :type => type,
        :project => project)

    issue   = FactoryGirl.create(:issue,
        :subject => 'My awesome Ticket',
        :type => type,
        :project => project,
        :description => "nothing here yet")

    # now change the issue, to get a nice journal
    # we create a Filesystem repository for our changeset, so we have to enable it
    Setting.enabled_scm = Setting.enabled_scm.dup << 'Filesystem' unless Setting.enabled_scm.include?('Filesystem')
    changeset = FactoryGirl.create :changeset,
                                   :repository => FactoryGirl.create(:repository, :project => project),
                                   :comments => 'This commit fixes #1, #2 and references #1 and #3'
    attachment = FactoryGirl.create(:attachment,
        :container => issue,
        :author => issue.author)
    issue.description = "This is related to issue ##{related_issue.id}\n A reference to a changeset r#{changeset.revision}\n A reference to an attachment attachment:#{attachment.filename}"
    assert issue.save
    issue.reload
    journal = issue.journals.last

    ActionMailer::Base.deliveries = [] # remove issue-created mails

    [project, user, related_issue, issue, changeset, attachment, journal]
  end
end
