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
  include ActionView::Helpers::SanitizeHelper

  class UnauthorizedAction < StandardError; end
  class MissingInformation < StandardError; end
  
  attr_reader :email, :user

  def self.receive(email, options={})
    @@handler_options = options.dup
    
    @@handler_options[:issue] ||= {}
    
    @@handler_options[:allow_override] = @@handler_options[:allow_override].split(',').collect(&:strip) if @@handler_options[:allow_override].is_a?(String)
    @@handler_options[:allow_override] ||= []
    # Project needs to be overridable if not specified
    @@handler_options[:allow_override] << 'project' unless @@handler_options[:issue].has_key?(:project)
    # Status overridable by default
    @@handler_options[:allow_override] << 'status' unless @@handler_options[:issue].has_key?(:status)    
    super email
  end
  
  # Processes incoming emails
  def receive(email)
    @email = email
    @user = User.active.find_by_mail(email.from.first.to_s.strip)
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

  MESSAGE_ID_RE = %r{^<redmine\.([a-z0-9_]+)\-(\d+)\.\d+@}
  ISSUE_REPLY_SUBJECT_RE = %r{\[[^\]]+#(\d+)\]}
  MESSAGE_REPLY_SUBJECT_RE = %r{\[[^\]]+msg(\d+)\]}
  
  def dispatch
    headers = [email.in_reply_to, email.references].flatten.compact
    if headers.detect {|h| h.to_s =~ MESSAGE_ID_RE}
      klass, object_id = $1, $2.to_i
      method_name = "receive_#{klass}_reply"
      if self.class.private_instance_methods.include?(method_name)
        send method_name, object_id
      else
        # ignoring it
      end
    elsif m = email.subject.match(ISSUE_REPLY_SUBJECT_RE)
      receive_issue_reply(m[1].to_i)
    elsif m = email.subject.match(MESSAGE_REPLY_SUBJECT_RE)
      receive_message_reply(m[1].to_i)
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
    tracker = (get_keyword(:tracker) && project.trackers.find_by_name(get_keyword(:tracker))) || project.trackers.find(:first)
    category = (get_keyword(:category) && project.issue_categories.find_by_name(get_keyword(:category)))
    priority = (get_keyword(:priority) && Enumeration.find_by_opt_and_name('IPRI', get_keyword(:priority)))
    status =  (get_keyword(:status) && IssueStatus.find_by_name(get_keyword(:status)))

    # check permission
    raise UnauthorizedAction unless user.allowed_to?(:add_issues, project)
    issue = Issue.new(:author => user, :project => project, :tracker => tracker, :category => category, :priority => priority)
    # check workflow
    if status && issue.new_statuses_allowed_to(user).include?(status)
      issue.status = status
    end
    issue.subject = email.subject.chomp.toutf8
    issue.description = plain_text_body
    # custom fields
    issue.custom_field_values = issue.available_custom_fields.inject({}) do |h, c|
      if value = get_keyword(c.name, :override => true)
        h[c.id] = value
      end
      h
    end
    issue.save!
    add_attachments(issue)
    logger.info "MailHandler: issue ##{issue.id} created by #{user}" if logger && logger.info
    # add To and Cc as watchers
    add_watchers(issue)
    # send notification after adding watchers so that they can reply to Redmine
    Mailer.deliver_issue_add(issue) if Setting.notified_events.include?('issue_added')
    issue
  end
  
  def target_project
    # TODO: other ways to specify project:
    # * parse the email To field
    # * specific project (eg. Setting.mail_handler_target_project)
    target = Project.find_by_identifier(get_keyword(:project))
    raise MissingInformation.new('Unable to determine target project') if target.nil?
    target
  end
  
  # Adds a note to an existing issue
  def receive_issue_reply(issue_id)
    status =  (get_keyword(:status) && IssueStatus.find_by_name(get_keyword(:status)))
    
    issue = Issue.find_by_id(issue_id)
    return unless issue
    # check permission
    raise UnauthorizedAction unless user.allowed_to?(:add_issue_notes, issue.project) || user.allowed_to?(:edit_issues, issue.project)
    raise UnauthorizedAction unless status.nil? || user.allowed_to?(:edit_issues, issue.project)

    # add the note
    journal = issue.init_journal(user, plain_text_body)
    add_attachments(issue)
    # check workflow
    if status && issue.new_statuses_allowed_to(user).include?(status)
      issue.status = status
    end
    issue.save!
    logger.info "MailHandler: issue ##{issue.id} updated by #{user}" if logger && logger.info
    Mailer.deliver_issue_edit(journal) if Setting.notified_events.include?('issue_updated')
    journal
  end
  
  # Reply will be added to the issue
  def receive_journal_reply(journal_id)
    journal = Journal.find_by_id(journal_id)
    if journal && journal.journalized_type == 'Issue'
      receive_issue_reply(journal.journalized_id)
    end
  end
  
  # Receives a reply to a forum message
  def receive_message_reply(message_id)
    message = Message.find_by_id(message_id)
    if message
      message = message.root
      if user.allowed_to?(:add_messages, message.project) && !message.locked?
        reply = Message.new(:subject => email.subject.gsub(%r{^.*msg\d+\]}, '').strip,
                            :content => plain_text_body)
        reply.author = user
        reply.board = message.board
        message.children << reply
        add_attachments(reply)
        reply
      else
        raise UnauthorizedAction
      end
    end
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
  
  # Adds To and Cc as watchers of the given object if the sender has the
  # appropriate permission
  def add_watchers(obj)
    if user.allowed_to?("add_#{obj.class.name.underscore}_watchers".to_sym, obj.project)
      addresses = [email.to, email.cc].flatten.compact.uniq.collect {|a| a.strip.downcase}
      unless addresses.empty?
        watchers = User.active.find(:all, :conditions => ['LOWER(mail) IN (?)', addresses])
        watchers.each {|w| obj.add_watcher(w)}
      end
    end
  end
  
  def get_keyword(attr, options={})
    @keywords ||= {}
    if @keywords.has_key?(attr)
      @keywords[attr]
    else
      @keywords[attr] = begin
        if (options[:override] || @@handler_options[:allow_override].include?(attr.to_s)) && plain_text_body.gsub!(/^#{attr}:[ \t]*(.+)\s*$/i, '')
          $1.strip
        elsif !@@handler_options[:issue][attr].blank?
          @@handler_options[:issue][attr]
        end
      end
    end
  end
  
  # Returns the text/plain part of the email
  # If not found (eg. HTML-only email), returns the body with tags removed
  def plain_text_body
    return @plain_text_body unless @plain_text_body.nil?
    parts = @email.parts.collect {|c| (c.respond_to?(:parts) && !c.parts.empty?) ? c.parts : c}.flatten
    if parts.empty?
      parts << @email
    end
    plain_text_part = parts.detect {|p| p.content_type == 'text/plain'}
    if plain_text_part.nil?
      # no text/plain part found, assuming html-only email
      # strip html tags and remove doctype directive
      @plain_text_body = strip_tags(@email.body.to_s)
      @plain_text_body.gsub! %r{^<!DOCTYPE .*$}, ''
    else
      @plain_text_body = plain_text_part.body.to_s
    end
    @plain_text_body.strip!
  end
  

  def self.full_sanitizer
    @full_sanitizer ||= HTML::FullSanitizer.new
  end
end
