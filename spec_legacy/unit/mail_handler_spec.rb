#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
require_relative '../legacy_spec_helper'

describe MailHandler, type: :model, with_settings: { report_incoming_email_errors: false } do
  fixtures :all

  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/mail_handler'

  it 'adds work package with japanese keywords' do
    type = ::Type.create!(name: '開発')
    Project.find(1).types << type
    issue = submit_email('japanese_keywords_iso_2022_jp.eml', issue: { project: 'ecookbook' }, allow_override: 'type')
    assert_kind_of WorkPackage, issue
    assert_equal type, issue.type
  end

  it 'adds work package with iso 8859 1 subject' do
    issue = submit_email(
      'subject_as_iso-8859-1.eml',
      issue: { project: 'ecookbook' }
    )
    assert_kind_of WorkPackage, issue
    assert_equal 'Testmail from Webmail: ä ö ü...', issue.subject
  end

  it 'strips tags of html only emails' do
    issue = submit_email('ticket_html_only.eml', issue: { project: 'ecookbook' })
    assert issue.is_a?(WorkPackage)
    assert !issue.new_record?
    issue.reload
    assert_equal 'HTML email', issue.subject
    assert_equal 'This is a html-only email.', issue.description
  end

  it 'emails with long subject line' do
    issue = submit_email('ticket_with_long_subject.eml')
    assert issue.is_a?(WorkPackage)
    assert_equal issue.subject,
                 'New ticket on a given project with a very long subject line which exceeds 255 chars and should not be ignored but chopped off. And if the subject line is still not long enough, we just add more text. And more text. Wow, this is really annoying. Especially, if you have nothing to say...'[
0, 255]
  end

  it 'news user from attributes should return valid user' do
    to_test = {
      # [address, name] => [login, firstname, lastname]
      ['jsmith@example.net', nil] => ['jsmith@example.net', 'jsmith', '-'],
      ['jsmith@example.net', 'John'] => ['jsmith@example.net', 'John', '-'],
      ['jsmith@example.net', 'John Smith'] => ['jsmith@example.net', 'John', 'Smith'],
      ['jsmith@example.net', 'John Paul Smith'] => ['jsmith@example.net', 'John', 'Paul Smith'],
      ['jsmith@example.net',
       'AVeryLongFirstnameThatNoLongerExceedsTheMaximumLength Smith'] => ['jsmith@example.net',
                                                                          'AVeryLongFirstnameThatNoLongerExceedsTheMaximumLength', 'Smith'],
      ['jsmith@example.net',
       'John AVeryLongLastnameThatNoLongerExceedsTheMaximumLength'] => ['jsmith@example.net', 'John',
                                                                        'AVeryLongLastnameThatNoLongerExceedsTheMaximumLength']
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
          with_legacy_settings: { password_min_length: 15 } do
    it 'news user from attributes should respect minimum password length' do
      user = MailHandler.new_user_from_attributes('jsmith@example.net')
      assert user.valid?
      assert user.password.length >= 15
    end
  end

  it 'news user from attributes should use default login if invalid' do
    user = MailHandler.new_user_from_attributes('foo&bar@example.net')
    assert user.valid?
    assert user.login =~ /^user[a-f0-9]+$/
    assert_equal 'foo&bar@example.net', user.mail
  end

  it 'news user with utf8 encoded fullname should be decoded' do
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
