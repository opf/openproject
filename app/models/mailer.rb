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
  helper ApplicationHelper
  helper IssuesHelper
  helper CustomFieldsHelper
  
  include ActionController::UrlWriter
  
  def issue_add(issue)    
    recipients issue.recipients    
    subject "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
    body :issue => issue,
         :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue)
  end

  def issue_edit(journal)
    issue = journal.journalized
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
  
  def document_added(document)
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
    when 'Version'
      added_to_url = url_for(:controller => 'projects', :action => 'list_files', :id => container.project_id)
      added_to = "#{l(:label_version)}: #{container.name}"
    when 'Document'
      added_to_url = url_for(:controller => 'documents', :action => 'show', :id => container.id)
      added_to = "#{l(:label_document)}: #{container.title}"
    end
    recipients container.project.recipients
    subject "[#{container.project.name}] #{l(:label_attachment_new)}"
    body :attachments => attachments,
         :added_to => added_to,
         :added_to_url => added_to_url
  end

  def news_added(news)
    recipients news.project.recipients
    subject "[#{news.project.name}] #{l(:label_news)}: #{news.title}"
    body :news => news,
         :news_url => url_for(:controller => 'news', :action => 'show', :id => news)
  end

  def message_posted(message, recipients)
    recipients(recipients)
    subject "[#{message.board.project.name} - #{message.board.name}] #{message.subject}"
    body :message => message,
         :message_url => url_for(:controller => 'messages', :action => 'show', :board_id => message.board_id, :id => message.root)
  end
   
  def account_information(user, password)
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_register)
    body :user => user,
         :password => password,
         :login_url => url_for(:controller => 'account', :action => 'login')
  end
  
  def account_activation_request(user)
    # Send the email to all active administrators
    recipients User.find_active(:all, :conditions => {:admin => true}).collect { |u| u.mail }.compact
    subject l(:mail_subject_account_activation_request)
    body :user => user,
         :url => url_for(:controller => 'users', :action => 'index', :status => User::STATUS_REGISTERED, :sort_key => 'created_on', :sort_order => 'desc')
  end

  def lost_password(token)
    set_language_if_valid(token.user.language)
    recipients token.user.mail
    subject l(:mail_subject_lost_password)
    body :token => token,
         :url => url_for(:controller => 'account', :action => 'lost_password', :token => token.value)
  end  

  def register(token)
    set_language_if_valid(token.user.language)
    recipients token.user.mail
    subject l(:mail_subject_register)
    body :token => token,
         :url => url_for(:controller => 'account', :action => 'activate', :token => token.value)
  end
  
  def test(user)
    set_language_if_valid(user.language)
    recipients user.mail
    subject 'Redmine test'
    body :url => url_for(:controller => 'welcome')
  end
  
  private
  def initialize_defaults(method_name)
    super
    set_language_if_valid Setting.default_language
    from Setting.mail_from
    default_url_options[:host] = Setting.host_name
    default_url_options[:protocol] = Setting.protocol
  end
  
  # Overrides the create_mail method
  def create_mail
    # Removes the current user from the recipients and cc
    # if he doesn't want to receive notifications about what he does
    if User.current.pref[:no_self_notified]
      recipients.delete(User.current.mail) if recipients
      cc.delete(User.current.mail) if cc
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
    layout = method_name.match(%r{text\.html\.(rhtml|rxml)}) ? 'layout.text.html.rhtml' : 'layout.text.plain.rhtml'
    body[:content_for_layout] = render(:file => method_name, :body => body)
    ActionView::Base.new(template_root, body, self).render(:file => "mailer/#{layout}")
  end
  
  # Makes partial rendering work with Rails 1.2 (retro-compatibility)
  def self.controller_path
    ''
  end unless respond_to?('controller_path')
end
