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

class MailHandlerTest < Test::Unit::TestCase
  fixtures :users, :projects, :roles, :members, :issues, :trackers, :enumerations
  
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
    @expected.mime_version = '1.0'
  end
  
  def test_add_note_to_issue
    raw = read_fixture("add_note_to_issue.txt").join
    MailHandler.receive(raw)

    issue = Issue.find(2)
    journal = issue.journals.find(:first, :order => "created_on DESC")
    assert journal
    assert_equal User.find_by_mail("jsmith@somenet.foo"), journal.user
    assert_equal "Note added by mail", journal.notes
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/mail_handler/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
