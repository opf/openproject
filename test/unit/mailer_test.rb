# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require File.dirname(__FILE__) + '/../test_helper'

class MailerTest < ActiveSupport::TestCase
  include Redmine::I18n
  fixtures :projects, :issues, :users, :members, :member_roles, :documents, :attachments, :news, :tokens, :journals, :journal_details, :changesets, :trackers, :issue_statuses, :enumerations, :messages, :boards, :repositories
  
  def test_generated_links_in_emails
    ActionMailer::Base.deliveries.clear
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'https'
    
    journal = Journal.find(2)
    assert Mailer.deliver_issue_edit(journal)
    
    mail = ActionMailer::Base.deliveries.last
    assert_kind_of TMail::Mail, mail
    # link to the main ticket
    assert mail.body.include?('<a href="https://mydomain.foo/issues/1">Bug #1: Can\'t print recipes</a>')
    
    # link to a referenced ticket
    assert mail.body.include?('<a href="https://mydomain.foo/issues/2" class="issue" title="Add ingredients categories (Assigned)">#2</a>')
    # link to a changeset
    assert mail.body.include?('<a href="https://mydomain.foo/projects/ecookbook/repository/revisions/2" class="changeset" title="This commit fixes #1, #2 and references #1 &amp; #3">r2</a>')
  end
  
  def test_generated_links_with_prefix
    relative_url_root = Redmine::Utils.relative_url_root
    ActionMailer::Base.deliveries.clear
    Setting.host_name = 'mydomain.foo/rdm'
    Setting.protocol = 'http'
    Redmine::Utils.relative_url_root = '/rdm'
    
    journal = Journal.find(2)
    assert Mailer.deliver_issue_edit(journal)
    
    mail = ActionMailer::Base.deliveries.last
    assert_kind_of TMail::Mail, mail
    # link to the main ticket
    assert mail.body.include?('<a href="http://mydomain.foo/rdm/issues/1">Bug #1: Can\'t print recipes</a>')
 
    # link to a referenced ticket
    assert mail.body.include?('<a href="http://mydomain.foo/rdm/issues/2" class="issue" title="Add ingredients categories (Assigned)">#2</a>')
    # link to a changeset
    assert mail.body.include?('<a href="http://mydomain.foo/rdm/projects/ecookbook/repository/revisions/2" class="changeset" title="This commit fixes #1, #2 and references #1 &amp; #3">r2</a>')
  ensure
    # restore it
    Redmine::Utils.relative_url_root = relative_url_root
  end
  
  def test_generated_links_with_prefix_and_no_relative_url_root
    relative_url_root = Redmine::Utils.relative_url_root
    ActionMailer::Base.deliveries.clear
    Setting.host_name = 'mydomain.foo/rdm'
    Setting.protocol = 'http'
    Redmine::Utils.relative_url_root = nil
    
    journal = Journal.find(2)
    assert Mailer.deliver_issue_edit(journal)
    
    mail = ActionMailer::Base.deliveries.last
    assert_kind_of TMail::Mail, mail
    # link to the main ticket
    assert mail.body.include?('<a href="http://mydomain.foo/rdm/issues/1">Bug #1: Can\'t print recipes</a>')
 
    # link to a referenced ticket
    assert mail.body.include?('<a href="http://mydomain.foo/rdm/issues/2" class="issue" title="Add ingredients categories (Assigned)">#2</a>')
    # link to a changeset
    assert mail.body.include?('<a href="http://mydomain.foo/rdm/projects/ecookbook/repository/revisions/2" class="changeset" title="This commit fixes #1, #2 and references #1 &amp; #3">r2</a>')
  ensure
    # restore it
    Redmine::Utils.relative_url_root = relative_url_root
  end
  
  def test_email_headers
    ActionMailer::Base.deliveries.clear
    issue = Issue.find(1)
    Mailer.deliver_issue_add(issue)
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal 'bulk', mail.header_string('Precedence')
    assert_equal 'auto-generated', mail.header_string('Auto-Submitted')
  end

  def test_plain_text_mail
    Setting.plain_text_mail = 1
    journal = Journal.find(2)
    Mailer.deliver_issue_edit(journal)
    mail = ActionMailer::Base.deliveries.last
    assert_equal 1, mail.parts.size
    assert !mail.encoded.include?('href')
  end

  def test_html_mail
    Setting.plain_text_mail = 0
    journal = Journal.find(2)
    Mailer.deliver_issue_edit(journal)
    mail = ActionMailer::Base.deliveries.last
    assert_equal 2, mail.parts.size
    assert mail.encoded.include?('href')
  end

  def test_issue_add_message_id
    ActionMailer::Base.deliveries.clear
    issue = Issue.find(1)
    Mailer.deliver_issue_add(issue)
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal Mailer.message_id_for(issue), mail.message_id
    assert_nil mail.references
  end
  
  def test_issue_edit_message_id
    ActionMailer::Base.deliveries.clear
    journal = Journal.find(1)
    Mailer.deliver_issue_edit(journal)
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal Mailer.message_id_for(journal), mail.message_id
    assert_equal Mailer.message_id_for(journal.issue), mail.references.first.to_s
  end
  
  def test_message_posted_message_id
    ActionMailer::Base.deliveries.clear
    message = Message.find(1)
    Mailer.deliver_message_posted(message, message.author.mail)
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal Mailer.message_id_for(message), mail.message_id
    assert_nil mail.references
  end
  
  def test_reply_posted_message_id
    ActionMailer::Base.deliveries.clear
    message = Message.find(3)
    Mailer.deliver_message_posted(message, message.author.mail)
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal Mailer.message_id_for(message), mail.message_id
    assert_equal Mailer.message_id_for(message.parent), mail.references.first.to_s
  end
  
  # test mailer methods for each language
  def test_issue_add
    issue = Issue.find(1)
    valid_languages.each do |lang|
      Setting.default_language = lang.to_s
      assert Mailer.deliver_issue_add(issue)
    end
  end

  def test_issue_edit
    journal = Journal.find(1)
    valid_languages.each do |lang|
      Setting.default_language = lang.to_s
      assert Mailer.deliver_issue_edit(journal)
    end
  end
  
  def test_document_added
    document = Document.find(1)
    valid_languages.each do |lang|
      Setting.default_language = lang.to_s
      assert Mailer.deliver_document_added(document)
    end
  end
  
  def test_attachments_added
    attachements = [ Attachment.find_by_container_type('Document') ]
    valid_languages.each do |lang|
      Setting.default_language = lang.to_s
      assert Mailer.deliver_attachments_added(attachements)
    end
  end
  
  def test_news_added
    news = News.find(:first)
    valid_languages.each do |lang|
      Setting.default_language = lang.to_s
      assert Mailer.deliver_news_added(news)
    end
  end
  
  def test_message_posted
    message = Message.find(:first)
    recipients = ([message.root] + message.root.children).collect {|m| m.author.mail if m.author}
    recipients = recipients.compact.uniq
    valid_languages.each do |lang|
      Setting.default_language = lang.to_s
      assert Mailer.deliver_message_posted(message, recipients)
    end
  end
  
  def test_account_information
    user = User.find(:first)
    valid_languages.each do |lang|
      user.update_attribute :language, lang.to_s
      user.reload
      assert Mailer.deliver_account_information(user, 'pAsswORd')
    end
  end

  def test_lost_password
    token = Token.find(2)
    valid_languages.each do |lang|
      token.user.update_attribute :language, lang.to_s
      token.reload
      assert Mailer.deliver_lost_password(token)
    end
  end

  def test_register
    token = Token.find(1)
    Setting.host_name = 'redmine.foo'
    Setting.protocol = 'https'
    
    valid_languages.each do |lang|
      token.user.update_attribute :language, lang.to_s
      token.reload
      ActionMailer::Base.deliveries.clear
      assert Mailer.deliver_register(token)
      mail = ActionMailer::Base.deliveries.last
      assert mail.body.include?("https://redmine.foo/account/activate?token=#{token.value}")
    end
  end
  
  def test_reminders
    ActionMailer::Base.deliveries.clear
    Mailer.reminders(:days => 42)
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries.last
    assert mail.bcc.include?('dlopper@somenet.foo')
    assert mail.body.include?('Bug #3: Error 281 when updating a recipe')
  end
end
