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

class MailerTest < Test::Unit::TestCase
  fixtures :projects, :issues, :users, :members, :documents, :attachments, :tokens, :journals, :journal_details, :trackers, :issue_statuses, :enumerations
  
  # test mailer methods for each language
  def test_issue_add
    issue = Issue.find(1)
    GLoc.valid_languages.each do |lang|
      Setting.default_language = lang
      assert Mailer.deliver_issue_add(issue)
    end
  end

  def test_issue_edit
    journal = Journal.find(1)
    GLoc.valid_languages.each do |lang|
      Setting.default_language = lang
      assert Mailer.deliver_issue_edit(journal)
    end
  end
  
  def test_document_add
    document = Document.find(1)
    GLoc.valid_languages.each do |lang|
      Setting.default_language = lang
      assert Mailer.deliver_document_add(document)
    end
  end

  def test_lost_password
    token = Token.find(2)
    GLoc.valid_languages.each do |lang|
      token.user.update_attribute :language, lang
      assert Mailer.deliver_lost_password(token)
    end
  end

  def test_register
    token = Token.find(1)
    GLoc.valid_languages.each do |lang|
      token.user.update_attribute :language, lang
      assert Mailer.deliver_register(token)
    end
  end
end