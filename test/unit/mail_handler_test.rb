#-- encoding: UTF-8
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

class MailHandlerTest < ActiveSupport::TestCase
  fixtures :all

  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/mail_handler'

  def setup
    super
    ActionMailer::Base.deliveries.clear
    Setting.notified_events = Redmine::Notifiable.all.collect(&:name)
  end

  def test_add_issue
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    issue = submit_email('ticket_on_given_project.eml', :allow_override => 'fixed_version')
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_equal Project.find(2), issue.project
    assert_equal issue.project.types.first, issue.type
    assert_equal 'New ticket on a given project', issue.subject
    assert_equal User.find_by_login('jsmith'), issue.author
    assert_equal IssueStatus.find_by_name('Resolved'), issue.status
    assert issue.description.include?('Lorem ipsum dolor sit amet, consectetuer adipiscing elit.')
    assert_equal '2010-01-01', issue.start_date.to_s
    assert_equal '2010-12-31', issue.due_date.to_s
    assert_equal User.find_by_login('jsmith'), issue.assigned_to
    assert_equal Version.find_by_name('alpha'), issue.fixed_version
    assert_equal 2.5, issue.estimated_hours
    assert_equal 30, issue.done_ratio
    assert_equal issue.id, issue.root_id
    assert issue.leaf?
    # keywords should be removed from the email body
    assert !issue.description.match(/^Project:/i)
    assert !issue.description.match(/^Status:/i)
    assert !issue.description.match(/^Start Date:/i)
    # Email notification should be sent
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert mail.subject.include?('New ticket on a given project')
  end

  def test_add_issue_with_default_type
    # This email contains: 'Project: onlinestore'
    issue = submit_email('ticket_on_given_project.eml', :issue => {:type => 'Support request'})
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_equal 'Support request', issue.type.name
  end

  def test_add_issue_with_status
    # This email contains: 'Project: onlinestore' and 'Status: Resolved'
    issue = submit_email('ticket_on_given_project.eml')
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_equal Project.find(2), issue.project
    assert_equal IssueStatus.find_by_name("Resolved"), issue.status
  end

  def test_add_issue_with_attributes_override
    issue = submit_email('ticket_with_attributes.eml', :allow_override => 'type,category,priority')
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_equal 'New ticket on a given project', issue.subject
    assert_equal User.find_by_login('jsmith'), issue.author
    assert_equal Project.find(2), issue.project
    assert_equal 'Feature request', issue.type.to_s
    assert_equal 'Stock management', issue.category.to_s
    assert_equal 'Urgent', issue.priority.to_s
    assert issue.description.include?('Lorem ipsum dolor sit amet, consectetuer adipiscing elit.')
  end

  def test_add_issue_with_partial_attributes_override
    issue = submit_email('ticket_with_attributes.eml', :issue => {:priority => 'High'}, :allow_override => ['type'])
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_equal 'New ticket on a given project', issue.subject
    assert_equal User.find_by_login('jsmith'), issue.author
    assert_equal Project.find(2), issue.project
    assert_equal 'Feature request', issue.type.to_s
    assert_nil issue.category
    assert_equal 'High', issue.priority.to_s
    assert issue.description.include?('Lorem ipsum dolor sit amet, consectetuer adipiscing elit.')
  end

  def test_add_issue_with_spaces_between_attribute_and_separator
    issue = submit_email('ticket_with_spaces_between_attribute_and_separator.eml', :allow_override => 'type,category,priority')
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_equal 'New ticket on a given project', issue.subject
    assert_equal User.find_by_login('jsmith'), issue.author
    assert_equal Project.find(2), issue.project
    assert_equal 'Feature request', issue.type.to_s
    assert_equal 'Stock management', issue.category.to_s
    assert_equal 'Urgent', issue.priority.to_s
    assert issue.description.include?('Lorem ipsum dolor sit amet, consectetuer adipiscing elit.')
  end


  def test_add_issue_with_attachment_to_specific_project
    issue = submit_email('ticket_with_attachment.eml', :issue => {:project => 'onlinestore'})
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_equal 'Ticket created by email with attachment', issue.subject
    assert_equal User.find_by_login('jsmith'), issue.author
    assert_equal Project.find(2), issue.project
    assert_equal 'This is  a new ticket with attachments', issue.description
    # Attachment properties
    assert_equal 1, issue.attachments.size
    assert_equal 'Paella.jpg', issue.attachments.first.filename
    assert_equal 'image/jpeg', issue.attachments.first.content_type
    assert_equal 10790, issue.attachments.first.filesize
  end

  def test_add_issue_with_custom_fields
    issue = submit_email('ticket_with_custom_fields.eml', :issue => {:project => 'onlinestore'})
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_equal 'New ticket with custom field values', issue.subject
    assert_equal 'Value for a custom field', issue.custom_value_for(CustomField.find_by_name('Searchable field')).value
    assert !issue.description.match(/^searchable field:/i)
  end

  def test_add_issue_should_match_assignee_on_display_name # added from redmine  - not sure if it is ok here
    user = User.generate!(:firstname => 'Foo Bar', :lastname => 'Foo Baz')
    User.add_to_project(user, Project.find(2), Role.generate!(:name => 'Superhero'))
    issue = submit_email('ticket_on_given_project.eml') do |email|
      email.sub!(/^Assigned to.*$/, 'Assigned to: Foo Bar Foo baz')
    end
    assert issue.is_a?(Issue)
    assert_equal user, issue.assigned_to
  end

  def test_add_issue_with_cc
    issue = submit_email('ticket_with_cc.eml', :issue => {:project => 'ecookbook'})
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert issue.watched_by?(User.find_by_mail('dlopper@somenet.foo'))
    assert_equal 1, issue.watcher_user_ids.size
  end

  def test_add_issue_by_unknown_user
    assert_no_difference 'User.count' do
      assert_equal false, submit_email('ticket_by_unknown_user.eml', :issue => {:project => 'ecookbook'})
    end
  end

  def test_add_issue_by_anonymous_user
    Role.anonymous.add_permission!(:add_issues)
    assert_no_difference 'User.count' do
      issue = submit_email('ticket_by_unknown_user.eml', :issue => {:project => 'ecookbook'}, :unknown_user => 'accept')
      assert issue.is_a?(Issue)
      assert issue.author.anonymous?
    end
  end

  def test_add_issue_by_anonymous_user_with_no_from_address
    Role.anonymous.add_permission!(:add_issues)
    assert_no_difference 'User.count' do
      issue = submit_email('ticket_by_empty_user.eml', :issue => {:project => 'ecookbook'}, :unknown_user => 'accept')
      assert issue.is_a?(Issue)
      assert issue.author.anonymous?
    end
  end

  def test_add_issue_by_anonymous_user_on_private_project
    Role.anonymous.add_permission!(:add_issues)
    assert_no_difference 'User.count' do
      assert_no_difference 'Issue.count' do
        assert_equal false, submit_email('ticket_by_unknown_user.eml', :issue => {:project => 'onlinestore'}, :unknown_user => 'accept')
      end
    end
  end

  def test_add_issue_by_anonymous_user_on_private_project_without_permission_check
    assert_no_difference 'User.count' do
      assert_difference 'Issue.count' do
        issue = submit_email('ticket_by_unknown_user.eml', :issue => {:project => 'onlinestore'}, :no_permission_check => '1', :unknown_user => 'accept')
        assert issue.is_a?(Issue)
        assert issue.author.anonymous?
        assert !issue.project.is_public?
        assert_equal issue.id, issue.root_id
        assert issue.leaf?
      end
    end
  end

  def test_add_issue_by_created_user
    Setting.default_language = 'en'
    assert_difference 'User.count' do
      issue = submit_email('ticket_by_unknown_user.eml', :issue => {:project => 'ecookbook'}, :unknown_user => 'create')
      assert issue.is_a?(Issue)
      assert issue.author.active?
      assert_equal 'john.doe@somenet.foo', issue.author.mail
      assert_equal 'John', issue.author.firstname
      assert_equal 'Doe', issue.author.lastname

      # account information
      email = ActionMailer::Base.deliveries.first
      assert_not_nil email
      assert email.subject.include?('account activation')
      login = email.body.encoded.match(/\* Login: (\S+)\s?$/)[1]
      password = email.body.encoded.match(/\* Password: (\S+)\s?$/)[1]

      # Can't log in here since randomly assigned password must be changed
      found_user = User.find_by_login(login)
      assert_equal issue.author, found_user
      assert found_user.check_password?(password)
    end
  end

  def test_add_issue_without_from_header
    Role.anonymous.add_permission!(:add_issues)
    assert_equal false, submit_email('ticket_without_from_header.eml')
  end

  def test_add_issue_with_invalid_attributes
    issue = submit_email('ticket_with_invalid_attributes.eml', :allow_override => 'type,category,priority')
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_nil issue.assigned_to
    assert_nil issue.start_date
    assert_nil issue.due_date
    assert_equal 0, issue.done_ratio
    assert_equal 'Normal', issue.priority.to_s
    assert issue.description.include?('Lorem ipsum dolor sit amet, consectetuer adipiscing elit.')
  end

  def test_add_issue_with_localized_attributes
    User.find_by_mail('jsmith@somenet.foo').update_attribute 'language', 'de'
    issue = submit_email('ticket_with_localized_attributes.eml', :allow_override => 'type,category,priority')
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_equal 'New ticket on a given project', issue.subject
    assert_equal User.find_by_login('jsmith'), issue.author
    assert_equal Project.find(2), issue.project
    assert_equal 'Feature request', issue.type.to_s
    assert_equal 'Stock management', issue.category.to_s
    assert_equal 'Urgent', issue.priority.to_s
    assert issue.description.include?('Lorem ipsum dolor sit amet, consectetuer adipiscing elit.')
  end

  def test_add_issue_with_japanese_keywords
    type = Type.create!(:name => '開発')
    Project.find(1).types << type
    issue = submit_email('japanese_keywords_iso_2022_jp.eml', :issue => {:project => 'ecookbook'}, :allow_override => 'type')
    assert_kind_of Issue, issue
    assert_equal type, issue.type
  end

  def test_add_issue_from_apple_mail
    issue = submit_email(
              'apple_mail_with_attachment.eml',
              :issue => {:project => 'ecookbook'}
            )
    assert_kind_of Issue, issue
    assert_equal 1, issue.attachments.size

    attachment = issue.attachments.first
    assert_equal 'paella.jpg', attachment.filename
    assert_equal 10790, attachment.filesize
    assert File.exist?(attachment.diskfile)
    assert_equal 10790, File.size(attachment.diskfile)
    assert_equal 'caaf384198bcbc9563ab5c058acd73cd', attachment.digest
  end

  def test_add_issue_with_iso_8859_1_subject
    issue = submit_email(
              'subject_as_iso-8859-1.eml',
              :issue => {:project => 'ecookbook'}
            )
    assert_kind_of Issue, issue
    assert_equal 'Testmail from Webmail: ä ö ü...', issue.subject
  end

  def test_should_ignore_emails_from_locked_users
    User.find(2).lock!

    MailHandler.any_instance.expects(:dispatch).never
    assert_no_difference 'Issue.count' do
      assert_equal false, submit_email('ticket_on_given_project.eml')
    end
  end

  def test_should_ignore_emails_from_emission_address
    Role.anonymous.add_permission!(:add_issues)
    assert_no_difference 'User.count' do
      assert !submit_email('ticket_from_emission_address.eml', :issue => { :project => 'ecookbook'}, :unknown_user => 'create')
    end
  end

  def test_should_ignore_auto_replied_emails
    MailHandler.any_instance.expects(:dispatch).never
    [
      "X-Auto-Response-Suppress: OOF",
      "Auto-Submitted: auto-replied",
      "Auto-Submitted: Auto-Replied",
      "Auto-Submitted: auto-generated"
    ].each do |header|
      raw = IO.read(File.join(FIXTURES_PATH, 'ticket_on_given_project.eml'))
      raw = header + "\n" + raw

      assert_no_difference 'Issue.count' do
        assert_equal false, MailHandler.receive(raw), "email with #{header} header was not ignored"
      end
    end
  end

  def test_add_issue_should_send_email_notification
    Setting.notified_events = ['issue_added']
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    issue = submit_email('ticket_on_given_project.eml')
    assert issue.is_a?(Issue)
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_add_issue_note
    journal = submit_email('ticket_reply.eml')
    assert journal.is_a?(Journal)
    assert_equal User.find_by_login('jsmith'), journal.user
    assert_equal Issue.find(2), journal.journable
    assert_match /This is reply/, journal.notes
    assert_equal 'Feature request', journal.journable.type.name
  end

  test "reply to issue update (Journal) by message_id" do
    Journal.delete_all
    issue = WorkPackage.find(2)
    j = FactoryGirl.create :work_package_journal,
                           id: 3,
                           journable_id: issue.id
    journal = submit_email('ticket_reply_by_message_id.eml')
    assert journal.data.is_a?(Journal::WorkPackageJournal), "Email was a #{journal.data.class}"
    assert_equal User.find_by_login('jsmith'), journal.user
    assert_equal Issue.find(2), journal.journable
    assert_match /This is reply/, journal.notes
    assert_equal 'Feature request', journal.journable.type.name
  end

  def test_add_issue_note_with_attribute_changes
    WorkPackage.find(2).recreate_initial_journal!
    # This email contains: 'Status: Resolved'
    journal = submit_email('ticket_reply_with_status.eml')
    assert journal.data.is_a?(Journal::WorkPackageJournal)
    issue = Issue.find(journal.journable.id)
    assert_equal User.find_by_login('jsmith'), journal.user
    assert_equal Issue.find(2), journal.journable
    assert_match /This is reply/, journal.notes
    assert_equal 'Feature request', journal.journable.type.name
    assert_equal IssueStatus.find_by_name("Resolved"), issue.status
    assert_equal '2010-01-01', issue.start_date.to_s
    assert_equal '2010-12-31', issue.due_date.to_s
    assert_equal User.find_by_login('jsmith'), issue.assigned_to
    assert_equal "52.6", issue.custom_value_for(CustomField.find_by_name('Float field')).value
    # keywords should be removed from the email body
    assert !journal.notes.match(/^Status:/i)
    assert !journal.notes.match(/^Start Date:/i)
  end

  def test_add_issue_note_should_send_email_notification
    WorkPackage.find(2).recreate_initial_journal!
    ActionMailer::Base.deliveries.clear
    journal = submit_email('ticket_reply.eml')
    assert journal.is_a?(Journal)
    assert_equal 3, ActionMailer::Base.deliveries.size
  end

  def test_add_issue_note_should_not_set_defaults
    journal = submit_email('ticket_reply.eml', :issue => {:type => 'Support request', :priority => 'High'})
    assert journal.is_a?(Journal)
    assert_match /This is reply/, journal.notes
    assert_equal 'Feature request', journal.journable.type.name
    assert_equal 'Normal', journal.journable.priority.name
  end

  def test_reply_to_a_message
    m = submit_email('message_reply.eml')
    assert m.is_a?(Message)
    assert !m.new_record?
    m.reload
    assert_equal 'Reply via email', m.subject
    # The email replies to message #2 which is part of the thread of message #1
    assert_equal Message.find(1), m.parent
  end

  def test_reply_to_a_message_by_subject
    m = submit_email('message_reply_by_subject.eml')
    assert m.is_a?(Message)
    assert !m.new_record?
    m.reload
    assert_equal 'Reply to the first post', m.subject
    assert_equal Message.find(1), m.parent
  end

  def test_should_strip_tags_of_html_only_emails
    issue = submit_email('ticket_html_only.eml', :issue => {:project => 'ecookbook'})
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_equal 'HTML email', issue.subject
    assert_equal 'This is a html-only email.', issue.description
  end

  context "truncate emails based on the Setting" do
    context "with no setting" do
      setup do
        Setting.mail_handler_body_delimiters = ''
      end

      should "add the entire email into the issue" do
        issue = submit_email('ticket_on_given_project.eml')
        assert_issue_created(issue)
        assert issue.description.include?('---')
        assert issue.description.include?('This paragraph is after the delimiter')
      end
    end

    context "with a single string" do
      setup do
        Setting.mail_handler_body_delimiters = '---'
      end

      should "truncate the email at the delimiter for the issue" do
        issue = submit_email('ticket_on_given_project.eml')
        assert_issue_created(issue)
        assert issue.description.include?('This paragraph is before delimiters')
        assert issue.description.include?('--- This line starts with a delimiter')
        assert !issue.description.match(/^---$/)
        assert !issue.description.include?('This paragraph is after the delimiter')
      end
    end

    context "with a single quoted reply (e.g. reply to a Redmine email notification)" do
      setup do
        Setting.mail_handler_body_delimiters = '--- Reply above. Do not remove this line. ---'
      end

      should "truncate the email at the delimiter with the quoted reply symbols (>)" do
        journal = submit_email('issue_update_with_quoted_reply_above.eml')
        assert journal.is_a?(Journal)
        assert journal.notes.include?('An update to the issue by the sender.')
        assert !journal.notes.match(Regexp.escape("--- Reply above. Do not remove this line. ---"))
        assert !journal.notes.include?('Looks like the JSON api for projects was missed.')

      end

    end

    context "with multiple quoted replies (e.g. reply to a reply of a Redmine email notification)" do
      setup do
        Setting.mail_handler_body_delimiters = '--- Reply above. Do not remove this line. ---'
      end

      should "truncate the email at the delimiter with the quoted reply symbols (>)" do
        journal = submit_email('issue_update_with_multiple_quoted_reply_above.eml')
        assert journal.is_a?(Journal)
        assert journal.notes.include?('An update to the issue by the sender.')
        assert !journal.notes.match(Regexp.escape("--- Reply above. Do not remove this line. ---"))
        assert !journal.notes.include?('Looks like the JSON api for projects was missed.')

      end

    end

    context "with multiple strings" do
      setup do
        Setting.mail_handler_body_delimiters = "---\nBREAK"
      end

      should "truncate the email at the first delimiter found (BREAK)" do
        issue = submit_email('ticket_on_given_project.eml')
        assert_issue_created(issue)
        assert issue.description.include?('This paragraph is before delimiters')
        assert !issue.description.include?('BREAK')
        assert !issue.description.include?('This paragraph is between delimiters')
        assert !issue.description.match(/^---$/)
        assert !issue.description.include?('This paragraph is after the delimiter')
      end
    end
  end

  def test_email_with_long_subject_line
    issue = submit_email('ticket_with_long_subject.eml')
    assert issue.is_a?(Issue)
    assert_equal issue.subject, 'New ticket on a given project with a very long subject line which exceeds 255 chars and should not be ignored but chopped off. And if the subject line is still not long enough, we just add more text. And more text. Wow, this is really annoying. Especially, if you have nothing to say...'[0,255]
  end

  def test_new_user_from_attributes_should_return_valid_user
    to_test = {
      # [address, name] => [login, firstname, lastname]
      ['jsmith@example.net', nil] => ['jsmith@example.net', 'jsmith', '-'],
      ['jsmith@example.net', 'John'] => ['jsmith@example.net', 'John', '-'],
      ['jsmith@example.net', 'John Smith'] => ['jsmith@example.net', 'John', 'Smith'],
      ['jsmith@example.net', 'John Paul Smith'] => ['jsmith@example.net', 'John', 'Paul Smith'],
      # TODO: implement https://github.com/redmine/redmine/commit/a00f04886fac78e489bb030d20414ebdf10841e3
      # ['jsmith@example.net', 'AVeryLongFirstnameThatExceedsTheMaximumLength Smith'] => ['jsmith@example.net', 'AVeryLongFirstnameThatExceedsT', 'Smith'],
      # ['jsmith@example.net', 'John AVeryLongLastnameThatExceedsTheMaximumLength'] => ['jsmith@example.net', 'John', 'AVeryLongLastnameThatExceedsTh']
      ['jsmith@example.net', 'AVeryLongFirstnameThatExceedsTheMaximumLength Smith'] => ['jsmith@example.net', '-', 'Smith'],
      ['jsmith@example.net', 'John AVeryLongLastnameThatExceedsTheMaximumLength'] => ['jsmith@example.net', 'John', '-']
    }

    to_test.each do |attrs, expected|
      user = MailHandler.new_user_from_attributes(attrs.first, attrs.last)

      assert user.valid?, user.errors.full_messages.to_s
      assert_equal attrs.first, user.mail
      assert_equal expected[0], user.login
      assert_equal expected[1], user.firstname
      assert_equal expected[2], user.lastname
    end
  end

  def test_new_user_from_attributes_should_respect_minimum_password_length
    with_settings :password_min_length => 15 do
      user = MailHandler.new_user_from_attributes('jsmith@example.net')
      assert user.valid?
      assert user.password.length >= 15
    end
  end

  def test_new_user_from_attributes_should_use_default_login_if_invalid
    user = MailHandler.new_user_from_attributes('foo+bar@example.net')
    assert user.valid?
    assert user.login =~ /^user[a-f0-9]+$/
    assert_equal 'foo+bar@example.net', user.mail
  end

  def test_new_user_with_utf8_encoded_fullname_should_be_decoded
    assert_difference 'User.count' do
      issue = submit_email(
                'fullname_of_sender_as_utf8_encoded.eml',
                :issue => {:project => 'ecookbook'},
                :unknown_user => 'create'
              )
    end

    user = User.first(:order => 'id DESC')
    assert_equal "foo@example.org", user.mail
    str1 = "\xc3\x84\xc3\xa4"
    str2 = "\xc3\x96\xc3\xb6"
    str1.force_encoding('UTF-8') if str1.respond_to?(:force_encoding)
    str2.force_encoding('UTF-8') if str2.respond_to?(:force_encoding)
    assert_equal str1, user.firstname
    assert_equal str2, user.lastname
  end

  private

  def submit_email(filename, options={})
    raw = IO.read(File.join(FIXTURES_PATH, filename))
    yield raw if block_given?
    MailHandler.receive(raw, options)
  end

  def assert_issue_created(issue)
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
  end
end
