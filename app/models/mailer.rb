#-- encoding: UTF-8
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

require 'ar_condition'

class Mailer < ActionMailer::Base
  layout 'mailer'
  helper :application
  helper :issues
  helper :journals
  helper :custom_fields

  include ActionController::UrlWriter
  include Redmine::I18n

  def self.default_url_options
    h = Setting.host_name
    h = h.to_s.gsub(%r{\/.*$}, '') unless Redmine::Utils.relative_url_root.blank?
    { :host => h, :protocol => Setting.protocol }
  end

  # Builds a tmail object used to email a recipient of the added issue.
  #
  # Example:
  #   issue_add(issue, 'user@example.com') => tmail object
  #   Mailer.deliver_issue_add(issue, 'user@example.com') => sends an email to 'user@example.com'
  def issue_add(issue, recipient)
    redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login,
                    'Type' => "Issue"
    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    message_id issue
    recipients [recipient]
    subject "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
    body :issue => issue,
         :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue)
    render_multipart('issue_add', body)
  end

  # Builds a tmail object used to email recipients of the edited issue.
  #
  # Example:
  #   issue_edit(journal, 'user@example.com') => tmail object
  #   Mailer.deliver_issue_edit(journal, 'user@example.com') => sends an email to issue recipients
  def issue_edit(journal, recipient)
    issue = journal.journaled.reload
    redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login,
                    'Type' => "Issue"
    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    message_id journal
    references issue
    @author = journal.user
    recipients [recipient]
    s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
    s << "(#{issue.status.name}) " if journal.details['status_id']
    s << issue.subject
    subject s
    body :issue => issue,
         :journal => journal,
         :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue)

    render_multipart('issue_edit', body)
  end

  def reminder(user, issues, days)
    redmine_headers 'Type' => "Issue"
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_reminder, :count => issues.size, :days => days)
    body :issues => issues,
         :days => days,
         :issues_url => url_for(:controller => 'issues', :action => 'index', :set_filter => 1, :assigned_to_id => user.id, :sort => 'due_date:asc')
    render_multipart('reminder', body)
  end

  # Builds a tmail object used to email users belonging to the added document's project.
  #
  # Example:
  #   document_added(document, 'test@example.com') => tmail object
  #   Mailer.deliver_document_added(document, 'test@example.com') => sends an email to the document's project recipients
  def document_added(document, recipient)
    redmine_headers 'Project' => document.project.identifier,
                    'Type' => "Document"
    recipients [recipient]
    subject "[#{document.project.name}] #{l(:label_document_new)}: #{document.title}"
    body :document => document,
         :document_url => url_for(:controller => 'documents', :action => 'show', :id => document)
    render_multipart('document_added', body)
  end

  # Builds a tmail object used to email recipients of a project when an attachements are added.
  #
  # Example:
  #   attachments_added(attachments) => tmail object
  #   Mailer.deliver_attachments_added(attachments) => sends an email to the project's recipients
  def attachments_added(attachments, recipient)
    container = attachments.first.container
    added_to = ''
    added_to_url = ''
    case container.class.name
    when 'Project'
      added_to_url = url_for(:controller => 'files', :action => 'index', :project_id => container)
      added_to = "#{l(:label_project)}: #{container}"
    when 'Version'
      added_to_url = url_for(:controller => 'files', :action => 'index', :project_id => container.project)
      added_to = "#{l(:label_version)}: #{container.name}"
    when 'Document'
      added_to_url = url_for(:controller => 'documents', :action => 'show', :id => container.id)
      added_to = "#{l(:label_document)}: #{container.title}"
    end
    recipients [recipient]
    redmine_headers 'Project' => container.project.identifier,
                    'Type' => "Attachment"
    subject "[#{container.project.name}] #{l(:label_attachment_new)}"
    body :attachments => attachments,
         :added_to => added_to,
         :added_to_url => added_to_url
    render_multipart('attachments_added', body)
  end

  # Builds a tmail object used to email recipients of a news' project when a news item is added.
  #
  # Example:
  #   news_added(news) => tmail object
  #   Mailer.deliver_news_added(news) => sends an email to the news' project recipients
  def news_added(news, recipient)
    redmine_headers 'Project' => news.project.identifier,
                    'Type' => "News"
    message_id news
    recipients [recipient]
    subject "[#{news.project.name}] #{l(:label_news)}: #{news.title}"
    body :news => news,
         :news_url => url_for(:controller => 'news', :action => 'show', :id => news)
    render_multipart('news_added', body)
  end

  # Builds a tmail object used to email recipients of a news' project when a news comment is added.
  #
  # Example:
  #   news_comment_added(comment) => tmail object
  #   Mailer.news_comment_added(comment) => sends an email to the news' project recipients
  def news_comment_added(comment)
    news = comment.commented
    redmine_headers 'Project' => news.project.identifier
    message_id comment
    recipients news.recipients
    cc news.watcher_recipients
    subject "Re: [#{news.project.name}] #{l(:label_news)}: #{news.title}"
    body :news => news,
         :comment => comment,
         :news_url => url_for(:controller => 'news', :action => 'show', :id => news)
    render_multipart('news_comment_added', body)
  end

  # Builds a tmail object used to email the recipients of the specified message that was posted.
  #
  # Example:
  #   message_posted(message) => tmail object
  #   Mailer.deliver_message_posted(message) => sends an email to the recipients
  def message_posted(message, recipient)
    redmine_headers 'Project' => message.project.identifier,
                    'Topic-Id' => (message.parent_id || message.id),
                    'Type' => "Forum"
    message_id message
    references message.parent unless message.parent.nil?
    recipients [recipient]
    subject "[#{message.board.project.name} - #{message.board.name} - msg#{message.root.id}] #{message.subject}"
    body :message => message,
         :message_url => url_for({ :controller => 'messages', :action => 'show', :board_id => message.board, :id => message.root, :r => message, :anchor => "message-#{message.id}" })
    render_multipart('message_posted', body)
  end

  # Builds a tmail object used to email the recipients of a project of the specified wiki content was added.
  #
  # Example:
  #   wiki_content_added(wiki_content) => tmail object
  #   Mailer.deliver_wiki_content_added(wiki_content) => sends an email to the project's recipients
  def wiki_content_added(wiki_content, recipient)
    redmine_headers 'Project' => wiki_content.project.identifier,
                    'Wiki-Page-Id' => wiki_content.page.id,
                    'Type' => "Wiki"
    message_id wiki_content
    recipients [recipient]
    subject "[#{wiki_content.project.name}] #{l(:mail_subject_wiki_content_added, :id => wiki_content.page.pretty_title)}"
    body :wiki_content => wiki_content,
         :wiki_content_url => url_for(:controller => 'wiki', :action => 'show', :project_id => wiki_content.project, :id => wiki_content.page.title)
    render_multipart('wiki_content_added', body)
  end

  # Builds a tmail object used to email the recipients of a project of the specified wiki content was updated.
  #
  # Example:
  #   wiki_content_updated(wiki_content) => tmail object
  #   Mailer.deliver_wiki_content_updated(wiki_content) => sends an email to the project's recipients
  def wiki_content_updated(wiki_content, recipient)
    redmine_headers 'Project' => wiki_content.project.identifier,
                    'Wiki-Page-Id' => wiki_content.page.id,
                    'Type' => "Wiki"
    message_id wiki_content
    recipients [recipient]
    subject "[#{wiki_content.project.name}] #{l(:mail_subject_wiki_content_updated, :id => wiki_content.page.pretty_title)}"
    body :wiki_content => wiki_content,
         :wiki_content_url => url_for(:controller => 'wiki', :action => 'show', :project_id => wiki_content.project, :id => wiki_content.page.title),
         :wiki_diff_url => url_for(:controller => 'wiki', :action => 'diff', :project_id => wiki_content.project, :id => wiki_content.page.title, :version => wiki_content.version)
    render_multipart('wiki_content_updated', body)
  end

  # Builds a tmail object used to email the specified user their account information.
  #
  # Example:
  #   account_information(user, password) => tmail object
  #   Mailer.deliver_account_information(user, password) => sends account information to the user
  def account_information(user, password)
    redmine_headers 'Type' => "Account"
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_register, Setting.app_title)
    body :user => user,
         :password => password,
         :login_url => url_for(:controller => 'account', :action => 'login')
    render_multipart('account_information', body)
  end

  # Builds a tmail object used to email all active administrators of an account activation request.
  #
  # Example:
  #   account_activation_request(user) => tmail object
  #   Mailer.deliver_account_activation_request(user)=> sends an email to all active administrators
  def account_activation_request(user)
    # Send the email to all active administrators
    redmine_headers 'Type' => "Account"
    recipients User.active.find(:all, :conditions => {:admin => true}).collect { |u| u.mail }.compact
    subject l(:mail_subject_account_activation_request, Setting.app_title)
    body :user => user,
         :url => url_for(:controller => 'users', :action => 'index', :status => User::STATUS_REGISTERED, :sort_key => 'created_on', :sort_order => 'desc')
    render_multipart('account_activation_request', body)
  end

  # Builds a tmail object used to email the specified user that their account was activated by an administrator.
  #
  # Example:
  #   account_activated(user) => tmail object
  #   Mailer.deliver_account_activated(user) => sends an email to the registered user
  def account_activated(user)
    redmine_headers 'Type' => "Account"
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_register, Setting.app_title)
    body :user => user,
         :login_url => url_for(:controller => 'account', :action => 'login')
    render_multipart('account_activated', body)
  end

  def lost_password(token)
    redmine_headers 'Type' => "Account"
    set_language_if_valid(token.user.language)
    recipients token.user.mail
    subject l(:mail_subject_lost_password, Setting.app_title)
    body :token => token,
         :url => url_for(:controller => 'account', :action => 'lost_password', :token => token.value)
    render_multipart('lost_password', body)
  end

  def register(token)
    redmine_headers 'Type' => "Account"
    set_language_if_valid(token.user.language)
    recipients token.user.mail
    subject l(:mail_subject_register, Setting.app_title)
    body :token => token,
         :url => url_for(:controller => 'account', :action => 'activate', :token => token.value)
    render_multipart('register', body)
  end

  def test(user)
    redmine_headers 'Type' => "Test"
    set_language_if_valid(user.language)
    recipients user.mail
    subject 'ChiliProject test'
    body :url => url_for(:controller => 'welcome')
    render_multipart('test', body)
  end

  # Overrides default deliver! method to prevent from sending an email
  # with no recipient, cc or bcc
  def deliver!(mail = @mail)
    set_language_if_valid @initial_language
    return false if (recipients.nil? || recipients.empty?) &&
                    (cc.nil? || cc.empty?) &&
                    (bcc.nil? || bcc.empty?)

    # Set Message-Id and References
    if @message_id_object
      mail.message_id = self.class.message_id_for(@message_id_object)
    end
    if @references_objects
      mail.references = @references_objects.collect {|o| self.class.message_id_for(o)}
    end

    # Log errors when raise_delivery_errors is set to false, Rails does not
    raise_errors = self.class.raise_delivery_errors
    self.class.raise_delivery_errors = true
    begin
      return super(mail)
    rescue Exception => e
      if raise_errors
        raise e
      elsif mylogger
        mylogger.error "The following error occured while sending email notification: \"#{e.message}\". Check your configuration in config/configuration.yml."
      end
    ensure
      self.class.raise_delivery_errors = raise_errors
    end
  end

  # Sends reminders to issue assignees
  # Available options:
  # * :days     => how many days in the future to remind about (defaults to 7)
  # * :tracker  => id of tracker for filtering issues (defaults to all trackers)
  # * :project  => id or identifier of project to process (defaults to all projects)
  # * :users    => array of user ids who should be reminded
  def self.reminders(options={})
    days = options[:days] || 7
    project = options[:project] ? Project.find(options[:project]) : nil
    tracker = options[:tracker] ? Tracker.find(options[:tracker]) : nil
    user_ids = options[:users]

    s = ARCondition.new ["#{IssueStatus.table_name}.is_closed = ? AND #{Issue.table_name}.due_date <= ?", false, days.day.from_now.to_date]
    s << "#{Issue.table_name}.assigned_to_id IS NOT NULL"
    s << ["#{Issue.table_name}.assigned_to_id IN (?)", user_ids] if user_ids.present?
    s << "#{Project.table_name}.status = #{Project::STATUS_ACTIVE}"
    s << "#{Issue.table_name}.project_id = #{project.id}" if project
    s << "#{Issue.table_name}.tracker_id = #{tracker.id}" if tracker

    issues_by_assignee = Issue.find(:all, :include => [:status, :assigned_to, :project, :tracker],
                                          :conditions => s.conditions
                                    ).group_by(&:assigned_to)
    issues_by_assignee.each do |assignee, issues|
      deliver_reminder(assignee, issues, days) if assignee && assignee.active?
    end
  end

  # Activates/desactivates email deliveries during +block+
  def self.with_deliveries(enabled = true, &block)
    was_enabled = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = !!enabled
    yield
  ensure
    ActionMailer::Base.perform_deliveries = was_enabled
  end

  private
  def initialize_defaults(method_name)
    super
    @initial_language = current_language
    set_language_if_valid Setting.default_language
    from Setting.mail_from

    # Common headers
    headers 'X-Mailer' => 'ChiliProject',
            'X-ChiliProject-Host' => Setting.host_name,
            'X-ChiliProject-Site' => Setting.app_title,
            'Precedence' => 'bulk',
            'Auto-Submitted' => 'auto-generated'
  end

  # Appends a Redmine header field (name is prepended with 'X-ChiliProject-')
  def redmine_headers(h)
    h.each { |k,v| headers["X-ChiliProject-#{k}"] = v }
  end

  # Overrides the create_mail method
  def create_mail
    # Removes the current user from the recipients and cc
    # if he doesn't want to receive notifications about what he does
    @author ||= User.current
    if @author.pref[:no_self_notified]
      recipients((recipients.is_a?(Array) ? recipients : [recipients]) - [@author.mail]) if recipients.present?
      cc((cc.is_a?(Array) ? cc : [cc]) - [@author.mail]) if cc.present?
    end

    notified_users = [recipients, cc].flatten.compact.uniq
    # Rails would log recipients only, not cc and bcc
    mylogger.info "Sending email notification to: #{notified_users.join(', ')}" if mylogger
    super
  end

  # Rails 2.3 has problems rendering implicit multipart messages with
  # layouts so this method will wrap an multipart messages with
  # explicit parts.
  #
  # https://rails.lighthouseapp.com/projects/8994/tickets/2338-actionmailer-mailer-views-and-content-type
  # https://rails.lighthouseapp.com/projects/8994/tickets/1799-actionmailer-doesnt-set-template_format-when-rendering-layouts

  def render_multipart(method_name, body)
    if Setting.plain_text_mail?
      content_type "text/plain"
      body render(:file => "#{method_name}.text.plain.rhtml", :body => body, :layout => 'mailer.text.plain.erb')
    else
      content_type "multipart/alternative"
      part :content_type => "text/plain", :body => render(:file => "#{method_name}.text.plain.rhtml", :body => body, :layout => 'mailer.text.plain.erb')
      part :content_type => "text/html", :body => render_message("#{method_name}.text.html.rhtml", body)
    end
  end

  # Makes partial rendering work with Rails 1.2 (retro-compatibility)
  def self.controller_path
    ''
  end unless respond_to?('controller_path')

  # Returns a predictable Message-Id for the given object
  def self.message_id_for(object)
    # id + timestamp should reduce the odds of a collision
    # as far as we don't send multiple emails for the same object
    timestamp = object.send(object.respond_to?(:created_on) ? :created_on : :updated_on)
    hash = "chiliproject.#{object.class.name.demodulize.underscore}-#{object.id}.#{timestamp.strftime("%Y%m%d%H%M%S")}"
    host = Setting.mail_from.to_s.gsub(%r{^.*@}, '')
    host = "#{::Socket.gethostname}.chiliproject" if host.empty?
    "<#{hash}@#{host}>"
  end

  private

  def message_id(object)
    @message_id_object = object
  end

  def references(object)
    @references_objects ||= []
    @references_objects << object
  end

  def mylogger
    RAILS_DEFAULT_LOGGER
  end
end

# Patch TMail so that message_id is not overwritten
module TMail
  class Mail
    def add_message_id( fqdn = nil )
      self.message_id ||= ::TMail::new_message_id(fqdn)
    end
  end
end
