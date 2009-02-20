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

class Mailer < ActionMailer::Base
  helper :application
  helper :issues
  helper :custom_fields

  include ActionController::UrlWriter

  def issue_add(issue)
    redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login
    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    message_id issue
    recipients issue.recipients
    cc(issue.watcher_recipients - @recipients)
    subject "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
    body :issue => issue,
         :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue)
  end

  def issue_edit(journal)
    issue = journal.journalized
    redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login
    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    message_id journal
    references issue
    @author = journal.user
    recipients issue.recipients
    # Watchers in cc
    cc(issue.watcher_recipients - @recipients)
    s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
    s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
    s << issue.subject
    subject s
    body :issue => issue,
         :journal => journal,
         :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue)
  end

  def reminder(user, issues, days)
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_reminder, issues.size)
    body :issues => issues,
         :days => days,
         :issues_url => url_for(:controller => 'issues', :action => 'index', :set_filter => 1, :assigned_to_id => user.id, :sort_key => 'due_date', :sort_order => 'asc')
  end

  def document_added(document)
    redmine_headers 'Project' => document.project.identifier
    recipients document.project.recipients
    subject "[#{document.project.name}] #{l(:label_document_new)}: #{document.title}"
    body :document => document,
         :document_url => url_for(:controller => 'documents', :action => 'show', :id => document)
  end

  def attachments_added(attachments)
    container = attachments.first.container
    added_to = ''
    added_to_url = ''
    case container.class.name
    when 'Project'
      added_to_url = url_for(:controller => 'projects', :action => 'list_files', :id => container)
      added_to = "#{l(:label_project)}: #{container}"
    when 'Version'
      added_to_url = url_for(:controller => 'projects', :action => 'list_files', :id => container.project_id)
      added_to = "#{l(:label_version)}: #{container.name}"
    when 'Document'
      added_to_url = url_for(:controller => 'documents', :action => 'show', :id => container.id)
      added_to = "#{l(:label_document)}: #{container.title}"
    end
    redmine_headers 'Project' => container.project.identifier
    recipients container.project.recipients
    subject "[#{container.project.name}] #{l(:label_attachment_new)}"
    body :attachments => attachments,
         :added_to => added_to,
         :added_to_url => added_to_url
  end

  def news_added(news)
    redmine_headers 'Project' => news.project.identifier
    message_id news
    recipients news.project.recipients
    subject "[#{news.project.name}] #{l(:label_news)}: #{news.title}"
    body :news => news,
         :news_url => url_for(:controller => 'news', :action => 'show', :id => news)
  end

  def message_posted(message, recipients)
    redmine_headers 'Project' => message.project.identifier,
                    'Topic-Id' => (message.parent_id || message.id)
    message_id message
    references message.parent unless message.parent.nil?
    recipients(recipients)
    subject "[#{message.board.project.name} - #{message.board.name} - msg#{message.root.id}] #{message.subject}"
    body :message => message,
         :message_url => url_for(:controller => 'messages', :action => 'show', :board_id => message.board_id, :id => message.root)
  end

  def account_information(user, password)
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_register, Setting.app_title)
    body :user => user,
         :password => password,
         :login_url => url_for(:controller => 'account', :action => 'login')
  end

  def account_activation_request(user)
    # Send the email to all active administrators
    recipients User.active.find(:all, :conditions => {:admin => true}).collect { |u| u.mail }.compact
    subject l(:mail_subject_account_activation_request, Setting.app_title)
    body :user => user,
         :url => url_for(:controller => 'users', :action => 'index', :status => User::STATUS_REGISTERED, :sort_key => 'created_on', :sort_order => 'desc')
  end

  # A registered user's account was activated by an administrator
  def account_activated(user)
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_register, Setting.app_title)
    body :user => user,
         :login_url => url_for(:controller => 'account', :action => 'login')
  end

  def lost_password(token)
    set_language_if_valid(token.user.language)
    recipients token.user.mail
    subject l(:mail_subject_lost_password, Setting.app_title)
    body :token => token,
         :url => url_for(:controller => 'account', :action => 'lost_password', :token => token.value)
  end

  def register(token)
    set_language_if_valid(token.user.language)
    recipients token.user.mail
    subject l(:mail_subject_register, Setting.app_title)
    body :token => token,
         :url => url_for(:controller => 'account', :action => 'activate', :token => token.value)
  end

  def test(user)
    set_language_if_valid(user.language)
    recipients user.mail
    subject 'Redmine test'
    body :url => url_for(:controller => 'welcome')
  end

  # Overrides default deliver! method to prevent from sending an email
  # with no recipient, cc or bcc
  def deliver!(mail = @mail)
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
    super(mail)
  end

  # Sends reminders to issue assignees
  # Available options:
  # * :days     => how many days in the future to remind about (defaults to 7)
  # * :tracker  => id of tracker for filtering issues (defaults to all trackers)
  # * :project  => id or identifier of project to process (defaults to all projects)
  def self.reminders(options={})
    days = options[:days] || 7
    project = options[:project] ? Project.find(options[:project]) : nil
    tracker = options[:tracker] ? Tracker.find(options[:tracker]) : nil

    s = ARCondition.new ["#{IssueStatus.table_name}.is_closed = ? AND #{Issue.table_name}.due_date <= ?", false, days.day.from_now.to_date]
    s << "#{Issue.table_name}.assigned_to_id IS NOT NULL"
    s << "#{Project.table_name}.status = #{Project::STATUS_ACTIVE}"
    s << "#{Issue.table_name}.project_id = #{project.id}" if project
    s << "#{Issue.table_name}.tracker_id = #{tracker.id}" if tracker

    issues_by_assignee = Issue.find(:all, :include => [:status, :assigned_to, :project, :tracker],
                                          :conditions => s.conditions
                                    ).group_by(&:assigned_to)
    issues_by_assignee.each do |assignee, issues|
      deliver_reminder(assignee, issues, days) unless assignee.nil?
    end
  end

  private
  def initialize_defaults(method_name)
    super
    set_language_if_valid Setting.default_language
    from Setting.mail_from
    
    # URL options
    h = Setting.host_name
    h = h.to_s.gsub(%r{\/.*$}, '') unless Redmine::Utils.relative_url_root.blank?
    default_url_options[:host] = h
    default_url_options[:protocol] = Setting.protocol
    
    # Common headers
    headers 'X-Mailer' => 'Redmine',
            'X-Redmine-Host' => Setting.host_name,
            'X-Redmine-Site' => Setting.app_title
  end

  # Appends a Redmine header field (name is prepended with 'X-Redmine-')
  def redmine_headers(h)
    h.each { |k,v| headers["X-Redmine-#{k}"] = v }
  end

  # Overrides the create_mail method
  def create_mail
    # Removes the current user from the recipients and cc
    # if he doesn't want to receive notifications about what he does
    @author ||= User.current
    if @author.pref[:no_self_notified]
      recipients.delete(@author.mail) if recipients
      cc.delete(@author.mail) if cc
    end
    # Blind carbon copy recipients
    if Setting.bcc_recipients?
      bcc([recipients, cc].flatten.compact.uniq)
      recipients []
      cc []
    end
    super
  end

  # Renders a message with the corresponding layout
  def render_message(method_name, body)
    layout = method_name.to_s.match(%r{text\.html\.(rhtml|rxml)}) ? 'layout.text.html.rhtml' : 'layout.text.plain.rhtml'
    body[:content_for_layout] = render(:file => method_name, :body => body)
    ActionView::Base.new(template_root, body, self).render(:file => "mailer/#{layout}", :use_full_path => true)
  end

  # for the case of plain text only
  def body(*params)
    value = super(*params)
    if Setting.plain_text_mail?
      templates = Dir.glob("#{template_path}/#{@template}.text.plain.{rhtml,erb}")
      unless String === @body or templates.empty?
        template = File.basename(templates.first)
        @body[:content_for_layout] = render(:file => template, :body => @body)
        @body = ActionView::Base.new(template_root, @body, self).render(:file => "mailer/layout.text.plain.rhtml", :use_full_path => true)
        return @body
      end
    end
    return value
  end

  # Makes partial rendering work with Rails 1.2 (retro-compatibility)
  def self.controller_path
    ''
  end unless respond_to?('controller_path')
  
  # Returns a predictable Message-Id for the given object
  def self.message_id_for(object)
    # id + timestamp should reduce the odds of a collision
    # as far as we don't send multiple emails for the same object
    hash = "redmine.#{object.class.name.demodulize.underscore}-#{object.id}.#{object.created_on.strftime("%Y%m%d%H%M%S")}"
    host = Setting.mail_from.to_s.gsub(%r{^.*@}, '')
    host = "#{::Socket.gethostname}.redmine" if host.empty?
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
end

# Patch TMail so that message_id is not overwritten
module TMail
  class Mail
    def add_message_id( fqdn = nil )
      self.message_id ||= ::TMail::new_message_id(fqdn)
    end
  end
end
