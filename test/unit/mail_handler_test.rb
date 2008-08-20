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
  fixtures :users, :projects, 
                   :enabled_modules,
                   :roles,
                   :members,
                   :issues,
                   :trackers,
                   :projects_trackers,
                   :enumerations,
                   :issue_categories
  
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/mail_handler'
  
  def setup
    ActionMailer::Base.deliveries.clear
  end
  
  def test_add_issue
    # This email contains: 'Project: onlinestore'
    issue = submit_email('ticket_on_given_project.eml')
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_equal 'New ticket on a given project', issue.subject
    assert_equal User.find_by_login('jsmith'), issue.author
    assert_equal Project.find(2), issue.project
    assert issue.description.include?('Lorem ipsum dolor sit amet, consectetuer adipiscing elit.')
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
    issue = submit_email('ticket_with_attributes.eml', :allow_override => 'tracker,category,priority')
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_equal 'New ticket on a given project', issue.subject
    assert_equal User.find_by_login('jsmith'), issue.author
    assert_equal Project.find(2), issue.project
    assert_equal 'Feature request', issue.tracker.to_s
    assert_equal 'Stock management', issue.category.to_s
    assert_equal 'Urgent', issue.priority.to_s
    assert issue.description.include?('Lorem ipsum dolor sit amet, consectetuer adipiscing elit.')
  end
  
  def test_add_issue_with_partial_attributes_override
    issue = submit_email('ticket_with_attributes.eml', :issue => {:priority => 'High'}, :allow_override => ['tracker'])
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
    assert_equal 'New ticket on a given project', issue.subject
    assert_equal User.find_by_login('jsmith'), issue.author
    assert_equal Project.find(2), issue.project
    assert_equal 'Feature request', issue.tracker.to_s
    assert_nil issue.category
    assert_equal 'High', issue.priority.to_s
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
  
  def test_add_issue_note
    journal = submit_email('ticket_reply.eml')
    assert journal.is_a?(Journal)
    assert_equal User.find_by_login('jsmith'), journal.user
    assert_equal Issue.find(2), journal.journalized
    assert_match /This is reply/, journal.notes
  end

  def test_add_issue_note_with_status_change
    # This email contains: 'Status: Resolved'
    journal = submit_email('ticket_reply_with_status.eml')
    assert journal.is_a?(Journal)
    issue = Issue.find(journal.issue.id)
    assert_equal User.find_by_login('jsmith'), journal.user
    assert_equal Issue.find(2), journal.journalized
    assert_match /This is reply/, journal.notes
    assert_equal IssueStatus.find_by_name("Resolved"), issue.status
  end

  private
  
  def submit_email(filename, options={})
    raw = IO.read(File.join(FIXTURES_PATH, filename))
    MailHandler.receive(raw, options)
  end
end
