#-- copyright
# ChiliProject is a project management system.
# 
# Copyright (C) 2010-2011 the ChiliProject Team
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# See doc/COPYRIGHT.rdoc for more details.
#++

class MailHandler < ActionMailer::Base
  include ActionView::Helpers::SanitizeHelper
  include Redmine::I18n

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
    
    @@handler_options[:no_permission_check] = (@@handler_options[:no_permission_check].to_s == '1' ? true : false)
    super email
  end
  
  # Processes incoming emails
  # Returns the created object (eg. an issue, a message) or false
  def receive(email)
    @email = email
    sender_email = email.from.to_a.first.to_s.strip
    # Ignore emails received from the application emission address to avoid hell cycles
    if sender_email.downcase == Setting.mail_from.to_s.strip.downcase
      logger.info  "MailHandler: ignoring email from emission address [#{sender_email}]" if logger && logger.info
      return false
    end
    @user = User.find_by_mail(sender_email) if sender_email.present?
    if @user && !@user.active?
      logger.info  "MailHandler: ignoring email from non-active user [#{@user.login}]" if logger && logger.info
      return false
    end
    if @user.nil?
      # Email was submitted by an unknown user
      case @@handler_options[:unknown_user]
      when 'accept'
        @user = User.anonymous
      when 'create'
        @user = MailHandler.create_user_from_email(email)
        if @user
          logger.info "MailHandler: [#{@user.login}] account created" if logger && logger.info
          Mailer.deliver_account_information(@user, @user.password)
        else
          logger.error "MailHandler: could not create account for [#{sender_email}]" if logger && logger.error
          return false
        end
      else
        # Default behaviour, emails from unknown users are ignored
        logger.info  "MailHandler: ignoring email from unknown user [#{sender_email}]" if logger && logger.info
        return false
      end
    end
    User.current = @user
    dispatch
  end
  
  private

  MESSAGE_ID_RE = %r{^<chiliproject\.([a-z0-9_]+)\-(\d+)\.\d+@}
  ISSUE_REPLY_SUBJECT_RE = %r{\[[^\]]*#(\d+)\]}
  MESSAGE_REPLY_SUBJECT_RE = %r{\[[^\]]*msg(\d+)\]}
  
  def dispatch
    headers = [email.in_reply_to, email.references].flatten.compact
    if headers.detect {|h| h.to_s =~ MESSAGE_ID_RE}
      klass, object_id = $1, $2.to_i
      method_name = "receive_#{klass}_reply"
      if self.class.private_instance_methods.collect(&:to_s).include?(method_name)
        send method_name, object_id
      else
        # ignoring it
      end
    elsif m = email.subject.match(ISSUE_REPLY_SUBJECT_RE)
      receive_issue_reply(m[1].to_i)
    elsif m = email.subject.match(MESSAGE_REPLY_SUBJECT_RE)
      receive_message_reply(m[1].to_i)
    else
      dispatch_to_default
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

  # Dispatch the mail to the default method handler, receive_issue
  #
  # This can be overridden or patched to support handling other incoming
  # email types
  def dispatch_to_default
    receive_issue
  end
  
  # Creates a new issue
  def receive_issue
    project = target_project
    # check permission
    unless @@handler_options[:no_permission_check]
      raise UnauthorizedAction unless user.allowed_to?(:add_issues, project)
    end

    issue = Issue.new(:author => user, :project => project)
    issue.safe_attributes = issue_attributes_from_keywords(issue)
    issue.safe_attributes = {'custom_field_values' => custom_field_values_from_keywords(issue)}
    issue.subject = email.subject.to_s.chomp[0,255]
    if issue.subject.blank?
      issue.subject = '(no subject)'
    end
    issue.description = cleaned_up_text_body
    
    # add To and Cc as watchers before saving so the watchers can reply to Redmine
    add_watchers(issue)
    issue.save!
    add_attachments(issue)
    logger.info "MailHandler: issue ##{issue.id} created by #{user}" if logger && logger.info
    issue
  end
  
  # Adds a note to an existing issue
  def receive_issue_reply(issue_id)
    issue = Issue.find_by_id(issue_id)
    return unless issue
    # check permission
    unless @@handler_options[:no_permission_check]
      raise UnauthorizedAction unless user.allowed_to?(:add_issue_notes, issue.project) || user.allowed_to?(:edit_issues, issue.project)
    end
    
    # ignore CLI-supplied defaults for new issues
    @@handler_options[:issue].clear
    
    issue.safe_attributes = issue_attributes_from_keywords(issue)
    issue.safe_attributes = {'custom_field_values' => custom_field_values_from_keywords(issue)}
    issue.init_journal(user, cleaned_up_text_body)
    add_attachments(issue)
    issue.save!
    logger.info "MailHandler: issue ##{issue.id} updated by #{user}" if logger && logger.info
    issue.last_journal
  end
  
  # Reply will be added to the issue
  def receive_journal_reply(journal_id)
    journal = Journal.find_by_id(journal_id)
    if journal and journal.journaled.is_a? Issue
      receive_issue_reply(journal.journaled_id)
    end
  end
  
  # Receives a reply to a forum message
  def receive_message_reply(message_id)
    message = Message.find_by_id(message_id)
    if message
      message = message.root
      
      unless @@handler_options[:no_permission_check]
        raise UnauthorizedAction unless user.allowed_to?(:add_messages, message.project)
      end
      
      if !message.locked?
        reply = Message.new(:subject => email.subject.gsub(%r{^.*msg\d+\]}, '').strip,
                            :content => cleaned_up_text_body)
        reply.author = user
        reply.board = message.board
        message.children << reply
        add_attachments(reply)
        reply
      else
        logger.info "MailHandler: ignoring reply from [#{sender_email}] to a locked topic" if logger && logger.info
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
        if (options[:override] || @@handler_options[:allow_override].include?(attr.to_s)) && (v = extract_keyword!(plain_text_body, attr, options[:format]))
          v
        elsif !@@handler_options[:issue][attr].blank?
          @@handler_options[:issue][attr]
        end
      end
    end
  end
  
  # Destructively extracts the value for +attr+ in +text+
  # Returns nil if no matching keyword found
  def extract_keyword!(text, attr, format=nil)
    keys = [attr.to_s.humanize]
    if attr.is_a?(Symbol)
      keys << l("field_#{attr}", :default => '', :locale =>  user.language) if user && user.language.present?
      keys << l("field_#{attr}", :default => '', :locale =>  Setting.default_language) if Setting.default_language.present?
    end
    keys.reject! {|k| k.blank?}
    keys.collect! {|k| Regexp.escape(k)}
    format ||= '.+'
    text.gsub!(/^(#{keys.join('|')})[ \t]*:[ \t]*(#{format})\s*$/i, '')
    $2 && $2.strip
  end

  def target_project
    # TODO: other ways to specify project:
    # * parse the email To field
    # * specific project (eg. Setting.mail_handler_target_project)
    target = Project.find_by_identifier(get_keyword(:project))
    raise MissingInformation.new('Unable to determine target project') if target.nil?
    target
  end
  
  # Returns a Hash of issue attributes extracted from keywords in the email body
  def issue_attributes_from_keywords(issue)
    assigned_to = (k = get_keyword(:assigned_to, :override => true)) && find_user_from_keyword(k)
    assigned_to = nil if assigned_to && !issue.assignable_users.include?(assigned_to)
    
    attrs = {
      'tracker_id' => (k = get_keyword(:tracker)) && issue.project.trackers.find_by_name(k).try(:id),
      'status_id' =>  (k = get_keyword(:status)) && IssueStatus.find_by_name(k).try(:id),
      'priority_id' => (k = get_keyword(:priority)) && IssuePriority.find_by_name(k).try(:id),
      'category_id' => (k = get_keyword(:category)) && issue.project.issue_categories.find_by_name(k).try(:id),
      'assigned_to_id' => assigned_to.try(:id),
      'fixed_version_id' => (k = get_keyword(:fixed_version, :override => true)) && issue.project.shared_versions.find_by_name(k).try(:id),
      'start_date' => get_keyword(:start_date, :override => true, :format => '\d{4}-\d{2}-\d{2}'),
      'due_date' => get_keyword(:due_date, :override => true, :format => '\d{4}-\d{2}-\d{2}'),
      'estimated_hours' => get_keyword(:estimated_hours, :override => true),
      'done_ratio' => get_keyword(:done_ratio, :override => true, :format => '(\d|10)?0')
    }.delete_if {|k, v| v.blank? }
    
    if issue.new_record? && attrs['tracker_id'].nil?
      attrs['tracker_id'] = issue.project.trackers.find(:first).try(:id)
    end
    
    attrs
  end
  
  # Returns a Hash of issue custom field values extracted from keywords in the email body
  def custom_field_values_from_keywords(customized)  
    customized.custom_field_values.inject({}) do |h, v|
      if value = get_keyword(v.custom_field.name, :override => true)
        h[v.custom_field.id.to_s] = value
      end
      h
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
    @plain_text_body
  end
  
  def cleaned_up_text_body
    cleanup_body(plain_text_body)
  end

  def self.full_sanitizer
    @full_sanitizer ||= HTML::FullSanitizer.new
  end
  
  # Creates a user account for the +email+ sender
  def self.create_user_from_email(email)
    addr = email.from_addrs.to_a.first
    if addr && !addr.spec.blank?
      user = User.new
      user.mail = addr.spec
      
      names = addr.name.blank? ? addr.spec.gsub(/@.*$/, '').split('.') : addr.name.split
      user.firstname = names.shift
      user.lastname = names.join(' ')
      user.lastname = '-' if user.lastname.blank?
      
      user.login = user.mail
      user.password = ActiveSupport::SecureRandom.hex(5)
      user.language = Setting.default_language
      user.save ? user : nil
    end
  end

  private
  
  # Removes the email body of text after the truncation configurations.
  def cleanup_body(body)
    delimiters = Setting.mail_handler_body_delimiters.to_s.split(/[\r\n]+/).reject(&:blank?).map {|s| Regexp.escape(s)}
    unless delimiters.empty?
      regex = Regexp.new("^[> ]*(#{ delimiters.join('|') })\s*[\r\n].*", Regexp::MULTILINE)
      body = body.gsub(regex, '')
    end
    body.strip
  end

  def find_user_from_keyword(keyword)
    user ||= User.find_by_mail(keyword)
    user ||= User.find_by_login(keyword)
    if user.nil? && keyword.match(/ /)
      firstname, lastname = *(keyword.split) # "First Last Throwaway"
      user ||= User.find_by_firstname_and_lastname(firstname, lastname)
    end
    user
  end
end
