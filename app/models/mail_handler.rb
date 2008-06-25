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

class MailHandler < ActionMailer::Base

  class UnauthorizedAction < StandardError; end
  class MissingInformation < StandardError; end
  
  attr_reader :email, :user

  def self.receive(email, options={})
    @@handler_options = options
    super email
  end
  
  # Processes incoming emails
  def receive(email)
    @email = email
    @user = User.find_active(:first, :conditions => {:mail => email.from.first})
    unless @user
      # Unknown user => the email is ignored
      # TODO: ability to create the user's account
      logger.info "MailHandler: email submitted by unknown user [#{email.from.first}]" if logger && logger.info
      return false
    end
    User.current = @user
    dispatch
  end
  
  private

  ISSUE_REPLY_SUBJECT_RE = %r{\[[^\]]+#(\d+)\]}
  
  def dispatch
    if m = email.subject.match(ISSUE_REPLY_SUBJECT_RE)
      receive_issue_update(m[1].to_i)
    else
      receive_issue
    end
  rescue ActiveRecord::RecordInvalid => e
    # TODO: send a email to the user
    logger.error e.message if logger
    false
  rescue MissingInformation => e
    logger.error "MailHandler: missing information from #{user}: #{e.message}" if logger
    false
  rescue UnauthorizedAction => e
    logger.error "MailHandler: unauthorized attempt from #{user}" if logger
    false
  end
  
  # Creates a new issue
  def receive_issue
    project = target_project
    # TODO: make the tracker configurable
    tracker = project.trackers.find(:first)
    # check permission
    raise UnauthorizedAction unless user.allowed_to?(:add_issues, project)
    issue = Issue.new(:author => user, :project => project, :tracker => tracker)
    issue.subject = email.subject.chomp
    issue.description = email.plain_text_body.chomp
    issue.save!
    add_attachments(issue)
    logger.info "MailHandler: issue ##{issue.id} created by #{user}" if logger && logger.info
    Mailer.deliver_issue_add(issue) if Setting.notified_events.include?('issue_added')
    issue
  end
  
  def target_project
    # TODO: other ways to specify project:
    # * parse the email To field
    # * specific project (eg. Setting.mail_handler_target_project)
    identifier = if !@@handler_options[:project].blank?
                   @@handler_options[:project]
                 elsif email.plain_text_body =~ %r{^Project:[ \t]*(.+)$}i
                    $1
                 end
                 
    target = Project.find_by_identifier(identifier.to_s)
    raise MissingInformation.new('Unable to determine target project') if target.nil?
    target
  end
  
  # Adds a note to an existing issue
  def receive_issue_update(issue_id)
    issue = Issue.find_by_id(issue_id)
    return unless issue
    # check permission
    raise UnauthorizedAction unless user.allowed_to?(:add_issue_notes, issue.project) || user.allowed_to?(:edit_issues, issue.project)
    # add the note
    journal = issue.init_journal(user, email.plain_text_body.chomp)
    add_attachments(issue)
    issue.save!
    logger.info "MailHandler: issue ##{issue.id} updated by #{user}" if logger && logger.info
    Mailer.deliver_issue_edit(journal) if Setting.notified_events.include?('issue_updated')
    journal
  end
  
  def add_attachments(obj)
    if email.has_attachments?
      email.attachments.each do |attachment|
        Attachment.create(:container => obj,
                          :file => attachment,
                          :author => user,
                          :content_type => attachment.content_type)
      end
    end
  end
end

class TMail::Mail
  # Returns body of the first plain text part found if any
  def plain_text_body
    return @plain_text_body unless @plain_text_body.nil?
    p = self.parts.collect {|c| (c.respond_to?(:parts) && !c.parts.empty?) ? c.parts : c}.flatten
    plain = p.detect {|c| c.content_type == 'text/plain'}
    @plain_text_body = plain.nil? ? self.body : plain.body
  end
end

