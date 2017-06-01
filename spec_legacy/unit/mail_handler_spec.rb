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
require 'legacy_spec_helper'

describe MailHandler, type: :model do
  fixtures :all

  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/mail_handler'

  before do
    allow(Setting).to receive(:notified_events).and_return(Redmine::Notifiable.all.map(&:name))
  end

  it 'should add work package' do
    # This email contains: 'Project: onlinestore'
    issue = submit_email('ticket_on_given_project.eml', allow_override: 'fixed_version')
    assert issue.is_a?(WorkPackage)
    assert !issue.new_record?
    issue.reload
    assert_equal Project.find(2), issue.project
    assert_equal issue.project.types.first, issue.type
    assert_equal 'New ticket on a given project', issue.subject
    assert_equal User.find_by_login('jsmith'), issue.author
    assert_equal Status.find_by(name: 'Resolved'), issue.status
    assert issue.description.include?('Lorem ipsum dolor sit amet, consectetuer adipiscing elit.')
    assert_equal '2010-01-01', issue.start_date.to_s
    assert_equal '2010-12-31', issue.due_date.to_s
    assert_equal User.find_by_login('jsmith'), issue.assigned_to
    assert_equal Version.find_by(name: 'alpha'), issue.fixed_version
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
    refute_nil mail
    assert mail.subject.include?('New ticket on a given project')
  end

  it 'should add work package with default type' do
    # This email contains: 'Project: onlinestore'
    issue = submit_email('ticket_on_given_project.eml', issue: { type: 'Support request' })
    assert issue.is_a?(WorkPackage)
    assert !issue.new_record?
    issue.reload
    assert_equal 'Support request', issue.type.name
  end

  it 'should add work package with status' do
    # This email contains: 'Project: onlinestore' and 'Status: Resolved'
    issue = submit_email('ticket_on_given_project.eml')
    assert issue.is_a?(WorkPackage)
    assert !issue.new_record?
    issue.reload
    assert_equal Project.find(2), issue.project
    assert_equal Status.find_by(name: 'Resolved'), issue.status
  end

  it 'should add work package with attributes override' do
    issue = submit_email('ticket_with_attributes.eml', allow_override: 'type,category,priority')
    assert issue.is_a?(WorkPackage)
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

  context 'with group assignment set',
          with_settings: { work_package_group_assignment: 1 } do
    it 'should add work package with group assignment' do
      work_package = submit_email('ticket_on_given_project.eml') do |email|
        email.gsub!('Assigned to: John Smith', 'Assigned to: B Team')
      end
      assert work_package.is_a?(WorkPackage)
      assert !work_package.new_record?
      work_package.reload
      assert_equal Group.find(11), work_package.assigned_to
    end
  end

  it 'should add work package with partial attributes override' do
    issue = submit_email('ticket_with_attributes.eml', issue: { priority: 'High' }, allow_override: ['type'])
    assert issue.is_a?(WorkPackage)
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

  it 'should add work package with spaces between attribute and separator' do
    issue = submit_email('ticket_with_spaces_between_attribute_and_separator.eml', allow_override: 'type,category,priority')
    assert issue.is_a?(WorkPackage)
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

  it 'should add work package with attachment to specific project' do
    issue = submit_email('ticket_with_attachment.eml', issue: { project: 'onlinestore' })
    assert issue.is_a?(WorkPackage)
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

  it 'should add work package with custom fields' do
    issue = submit_email('ticket_with_custom_fields.eml', issue: { project: 'onlinestore' })
    assert issue.is_a?(WorkPackage)
    assert !issue.new_record?
    issue.reload
    assert_equal 'New ticket with custom field values', issue.subject
    assert_equal 'Value for a custom field', issue.custom_value_for(CustomField.find_by(name: 'Searchable field')).value
    assert !issue.description.match(/^searchable field:/i)
  end

  it 'should add work package should match assignee on display name' do # added from redmine  - not sure if it is ok here
    user = FactoryGirl.create(:user, firstname: 'Foo', lastname: 'Bar')
    role = FactoryGirl.create(:role, name: 'Superhero')
    FactoryGirl.create(:member, user: user, project: Project.find(2), role_ids: [role.id])
    issue = submit_email('ticket_on_given_project.eml') do |email|
      email.sub!(/^Assigned to.*$/, 'Assigned to: Foo Bar')
    end
    assert issue.is_a?(WorkPackage)
    assert_equal user, issue.assigned_to
  end

  it 'should add work package with cc' do
    issue = submit_email('ticket_with_cc.eml', issue: { project: 'ecookbook' })
    assert issue.is_a?(WorkPackage)
    assert !issue.new_record?
    issue.reload
    assert issue.watched_by?(User.find_by_mail('dlopper@somenet.foo'))
    assert_equal 1, issue.watcher_user_ids.size
  end

  it 'should add work package by unknown user' do
    assert_no_difference 'User.count' do
      assert_equal false, submit_email('ticket_by_unknown_user.eml', issue: { project: 'ecookbook' })
    end
  end

  it 'should add work package by anonymous user' do
    Role.anonymous.add_permission!(:add_work_packages)
    assert_no_difference 'User.count' do
      issue = submit_email('ticket_by_unknown_user.eml', issue: { project: 'ecookbook' }, unknown_user: 'accept')
      assert issue.is_a?(WorkPackage)
      assert issue.author.anonymous?
    end
  end

  it 'should add work package by anonymous user with no from address' do
    Role.anonymous.add_permission!(:add_work_packages)
    assert_no_difference 'User.count' do
      issue = submit_email('ticket_by_empty_user.eml', issue: { project: 'ecookbook' }, unknown_user: 'accept')
      assert issue.is_a?(WorkPackage)
      assert issue.author.anonymous?
    end
  end

  it 'should add work package by anonymous user on private project' do
    Role.anonymous.add_permission!(:add_work_packages)
    assert_no_difference 'User.count' do
      assert_no_difference 'WorkPackage.count' do
        assert_equal false, submit_email('ticket_by_unknown_user.eml', issue: { project: 'onlinestore' }, unknown_user: 'accept')
      end
    end
  end

  it 'should add work package by anonymous user on private project without permission check' do
    assert_no_difference 'User.count' do
      assert_difference 'WorkPackage.count' do
        issue = submit_email('ticket_by_unknown_user.eml', issue: { project: 'onlinestore' }, no_permission_check: '1', unknown_user: 'accept')
        assert issue.is_a?(WorkPackage)
        assert issue.author.anonymous?
        assert !issue.project.is_public?
        assert_equal issue.id, issue.root_id
        assert issue.leaf?
      end
    end
  end

  it 'should add work package without from header' do
    Role.anonymous.add_permission!(:add_work_packages)
    assert_equal false, submit_email('ticket_without_from_header.eml')
  end

  it 'should add work package with invalid attributes' do
    issue = submit_email('ticket_with_invalid_attributes.eml', allow_override: 'type,category,priority')
    assert issue.is_a?(WorkPackage)
    assert !issue.new_record?
    issue.reload
    assert_nil issue.assigned_to
    assert_nil issue.start_date
    assert_nil issue.due_date
    assert_equal 0, issue.done_ratio
    assert_equal 'Normal', issue.priority.to_s
    assert issue.description.include?('Lorem ipsum dolor sit amet, consectetuer adipiscing elit.')
  end

  it 'should add work package with localized attributes' do
    User.find_by_mail('jsmith@somenet.foo').update_attribute 'language', 'de'
    issue = submit_email('ticket_with_localized_attributes.eml', allow_override: 'type,category,priority')
    assert issue.is_a?(WorkPackage)
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

  it 'should add work package with japanese keywords' do
    type = ::Type.create!(name: '開発')
    Project.find(1).types << type
    issue = submit_email('japanese_keywords_iso_2022_jp.eml', issue: { project: 'ecookbook' }, allow_override: 'type')
    assert_kind_of WorkPackage, issue
    assert_equal type, issue.type
  end

  it 'should add from apple mail' do
    issue = submit_email(
      'apple_mail_with_attachment.eml',
      issue: { project: 'ecookbook' }
    )
    assert_kind_of WorkPackage, issue
    assert_equal 1, issue.attachments.size

    attachment = issue.attachments.first
    assert_equal 'paella.jpg', attachment.filename
    assert_equal 10790, attachment.filesize
    assert File.exist?(attachment.diskfile)
    assert_equal 10790, File.size(attachment.diskfile)
    assert_equal 'caaf384198bcbc9563ab5c058acd73cd', attachment.digest
  end

  it 'should add work package with iso 8859 1 subject' do
    issue = submit_email(
      'subject_as_iso-8859-1.eml',
      issue: { project: 'ecookbook' }
    )
    assert_kind_of WorkPackage, issue
    assert_equal 'Testmail from Webmail: ä ö ü...', issue.subject
  end

  it 'should ignore emails from locked users' do
    User.find(2).lock!

    expect_any_instance_of(MailHandler).to receive(:dispatch).never
    assert_no_difference 'WorkPackage.count' do
      assert_equal false, submit_email('ticket_on_given_project.eml')
    end
  end

  it 'should ignore emails from emission address' do
    Role.anonymous.add_permission!(:add_work_packages)
    assert_no_difference 'User.count' do
      assert !submit_email('ticket_from_emission_address.eml', issue: { project: 'ecookbook' }, unknown_user: 'create')
    end
  end

  it 'should ignore auto replied emails' do
    expect_any_instance_of(MailHandler).to receive(:dispatch).never
    [
      'X-Auto-Response-Suppress: OOF',
      'Auto-Submitted: auto-replied',
      'Auto-Submitted: Auto-Replied',
      'Auto-Submitted: auto-generated'
    ].each do |header|
      raw = IO.read(File.join(FIXTURES_PATH, 'ticket_on_given_project.eml'))
      raw = header + "\n" + raw

      assert_no_difference 'WorkPackage.count' do
        assert_equal false, MailHandler.receive(raw), "email with #{header} header was not ignored"
      end
    end
  end

  it 'should add work package should send email notification' do
    Setting.notified_events = ['work_package_added']

    # This email contains: 'Project: onlinestore'
    issue = submit_email('ticket_on_given_project.eml')
    assert issue.is_a?(WorkPackage)
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  it 'should add work package note' do
    journal = submit_email('ticket_reply.eml')
    assert journal.is_a?(Journal)
    assert_equal User.find_by_login('jsmith'), journal.user
    assert_equal WorkPackage.find(2), journal.journable
    assert_match /This is reply/, journal.notes
    assert_equal 'Feature request', journal.journable.type.name
  end

  specify 'reply to issue update (Journal) by message_id' do
    Journal.delete_all
    issue = WorkPackage.find(2)
    j = FactoryGirl.create :work_package_journal, id: 3, journable_id: issue.id
    journal = submit_email('ticket_reply_by_message_id.eml')
    assert journal.data.is_a?(Journal::WorkPackageJournal), "Email was a #{journal.data.class}"
    assert_equal User.find_by_login('jsmith'), journal.user
    assert_equal WorkPackage.find(2), journal.journable
    assert_match /This is reply/, journal.notes
    assert_equal 'Feature request', journal.journable.type.name
  end

  it 'should add work package note with attribute changes' do
    WorkPackage.find(2).recreate_initial_journal!
    # This email contains: 'Status: Resolved'
    journal = submit_email('ticket_reply_with_status.eml')
    assert journal.data.is_a?(Journal::WorkPackageJournal)
    issue = WorkPackage.find(journal.journable.id)
    assert_equal User.find_by_login('jsmith'), journal.user
    assert_equal WorkPackage.find(2), journal.journable
    assert_match /This is reply/, journal.notes
    assert_equal 'Feature request', journal.journable.type.name
    assert_equal Status.find_by(name: 'Resolved'), issue.status
    assert_equal '2010-01-01', issue.start_date.to_s
    assert_equal '2010-12-31', issue.due_date.to_s
    assert_equal User.find_by_login('jsmith'), issue.assigned_to
    assert_equal '52.6', issue.custom_value_for(CustomField.find_by(name: 'Float field')).value
    # keywords should be removed from the email body
    assert !journal.notes.match(/^Status:/i)
    assert !journal.notes.match(/^Start Date:/i)
  end

  it 'should add work package note should send email notification' do
    WorkPackage.find(2).recreate_initial_journal!
    journal = submit_email('ticket_reply.eml')
    assert journal.is_a?(Journal)
    assert_equal 3, ActionMailer::Base.deliveries.size
  end

  it 'should add work package note should not set defaults' do
    journal = submit_email('ticket_reply.eml', issue: { type: 'Support request', priority: 'High' })
    assert journal.is_a?(Journal)
    assert_match /This is reply/, journal.notes
    assert_equal 'Feature request', journal.journable.type.name
    assert_equal 'Normal', journal.journable.priority.name
  end

  it 'should reply to a message' do
    m = submit_email('message_reply.eml')
    assert m.is_a?(Message)
    assert !m.new_record?
    m.reload
    assert_equal 'Reply via email', m.subject
    # The email replies to message #2 which is part of the thread of message #1
    assert_equal Message.find(1), m.parent
  end

  it 'should reply to a message by subject' do
    m = submit_email('message_reply_by_subject.eml')
    assert m.is_a?(Message)
    assert !m.new_record?
    m.reload
    assert_equal 'Reply to the first post', m.subject
    assert_equal Message.find(1), m.parent
  end

  it 'should strip tags of html only emails' do
    issue = submit_email('ticket_html_only.eml', issue: { project: 'ecookbook' })
    assert issue.is_a?(WorkPackage)
    assert !issue.new_record?
    issue.reload
    assert_equal 'HTML email', issue.subject
    assert_equal 'This is a html-only email.', issue.description
  end

  context 'truncate emails based on the Setting' do
    context 'with no setting' do
      before do
        Setting.mail_handler_body_delimiters = ''
      end

      it 'should add the entire email into the issue' do
        issue = submit_email('ticket_on_given_project.eml')
        assert_issue_created(issue)
        assert issue.description.include?('---')
        assert issue.description.include?('This paragraph is after the delimiter')
      end
    end

    context 'with a single string' do
      before do
        Setting.mail_handler_body_delimiters = '---'
      end

      it 'should truncate the email at the delimiter for the issue' do
        issue = submit_email('ticket_on_given_project.eml')
        assert_issue_created(issue)
        assert issue.description.include?('This paragraph is before delimiters')
        assert issue.description.include?('--- This line starts with a delimiter')
        assert !issue.description.match(/^---$/)
        assert !issue.description.include?('This paragraph is after the delimiter')
      end
    end

    context 'with a single quoted reply (e.g. reply to a Redmine email notification)' do
      before do
        Setting.mail_handler_body_delimiters = '--- Reply above. Do not remove this line. ---'
      end

      it 'should truncate the email at the delimiter with the quoted reply symbols (>)' do
        journal = submit_email('issue_update_with_quoted_reply_above.eml')
        assert journal.is_a?(Journal)
        assert journal.notes.include?('An update to the issue by the sender.')
        assert !journal.notes.match(Regexp.escape('--- Reply above. Do not remove this line. ---'))
        assert !journal.notes.include?('Looks like the JSON api for projects was missed.')
      end
    end

    context 'with multiple quoted replies (e.g. reply to a reply of a Redmine email notification)' do
      before do
        Setting.mail_handler_body_delimiters = '--- Reply above. Do not remove this line. ---'
      end

      it 'should truncate the email at the delimiter with the quoted reply symbols (>)' do
        journal = submit_email('issue_update_with_multiple_quoted_reply_above.eml')
        assert journal.is_a?(Journal)
        assert journal.notes.include?('An update to the issue by the sender.')
        assert !journal.notes.match(Regexp.escape('--- Reply above. Do not remove this line. ---'))
        assert !journal.notes.include?('Looks like the JSON api for projects was missed.')
      end
    end

    context 'with multiple strings' do
      before do
        Setting.mail_handler_body_delimiters = "---\nBREAK"
      end

      it 'should truncate the email at the first delimiter found (BREAK)' do
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

  it 'should email with long subject line' do
    issue = submit_email('ticket_with_long_subject.eml')
    assert issue.is_a?(WorkPackage)
    assert_equal issue.subject, 'New ticket on a given project with a very long subject line which exceeds 255 chars and should not be ignored but chopped off. And if the subject line is still not long enough, we just add more text. And more text. Wow, this is really annoying. Especially, if you have nothing to say...'[0, 255]
  end

  it 'should new user from attributes should return valid user' do
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

  context 'with min password length',
          with_settings: { password_min_length: 15 } do
    it 'should new user from attributes should respect minimum password length' do
      user = MailHandler.new_user_from_attributes('jsmith@example.net')
      assert user.valid?
      assert user.password.length >= 15
    end
  end

  it 'should new user from attributes should use default login if invalid' do
    user = MailHandler.new_user_from_attributes('foo&bar@example.net')
    assert user.valid?
    assert user.login =~ /^user[a-f0-9]+$/
    assert_equal 'foo&bar@example.net', user.mail
  end

  it 'should new user with utf8 encoded fullname should be decoded' do
    assert_difference 'User.count' do
      issue = submit_email(
        'fullname_of_sender_as_utf8_encoded.eml',
        issue: { project: 'ecookbook' },
        unknown_user: 'create'
      )
    end

    user = User.order('id DESC').first
    assert_equal 'foo@example.org', user.mail
    str1 = "\xc3\x84\xc3\xa4"
    str2 = "\xc3\x96\xc3\xb6"
    str1.force_encoding('UTF-8') if str1.respond_to?(:force_encoding)
    str2.force_encoding('UTF-8') if str2.respond_to?(:force_encoding)
    assert_equal str1, user.firstname
    assert_equal str2, user.lastname
  end

  private

  def submit_email(filename, options = {})
    raw = IO.read(File.join(FIXTURES_PATH, filename))
    yield raw if block_given?
    MailHandler.receive(raw, options)
  end

  def assert_issue_created(issue)
    assert issue.is_a?(WorkPackage)
    assert !issue.new_record?
    issue.reload
  end
end
