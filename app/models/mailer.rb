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
  helper IssuesHelper

  def issue_add(issue)
    set_language_if_valid(Setting.default_language)
    # Sends to all project members
    @recipients     = issue.project.members.collect { |m| m.user.mail if m.user.mail_notification }.compact
    @from           = Setting.mail_from
    @subject        = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] #{issue.status.name} - #{issue.subject}"
    @body['issue']  = issue
  end

  def issue_edit(journal)
    set_language_if_valid(Setting.default_language)
    # Sends to all project members
    issue = journal.journalized
    @recipients     = issue.project.members.collect { |m| m.user.mail if m.user.mail_notification }.compact
    # Watchers in cc
    @cc             = issue.watcher_recipients - @recipients
    @from           = Setting.mail_from
    @subject        = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] #{issue.status.name} - #{issue.subject}"
    @body['issue']  = issue
    @body['journal']= journal
  end
  
  def document_add(document)
    set_language_if_valid(Setting.default_language)
    @recipients     = document.project.users.collect { |u| u.mail if u.mail_notification }.compact
    @from           = Setting.mail_from
    @subject        = "[#{document.project.name}] #{l(:label_document_new)}: #{document.title}"
    @body['document'] = document
  end
  
  def attachments_add(attachments)
    set_language_if_valid(Setting.default_language)
    container = attachments.first.container
    url = "http://#{Setting.host_name}/"
    added_to = ""
    case container.class.to_s
    when 'Version'
      url << "projects/list_files/#{container.project_id}"
      added_to = "#{l(:label_version)}: #{container.name}"
    when 'Document'
      url << "documents/show/#{container.id}"
      added_to = "#{l(:label_document)}: #{container.title}"
    when 'Issue'
      url << "issues/show/#{container.id}"
      added_to = "#{container.tracker.name} ##{container.id}: #{container.subject}"
    end
    @recipients     = container.project.users.collect { |u| u.mail if u.mail_notification }.compact
    @from           = Setting.mail_from
    @subject        = "[#{container.project.name}] #{l(:label_attachment_new)}"
    @body['attachments'] = attachments
    @body['url']    = url
    @body['added_to'] = added_to
  end
  
  def lost_password(token)
    set_language_if_valid(token.user.language)
    @recipients     = token.user.mail
    @from           = Setting.mail_from
    @subject        = l(:mail_subject_lost_password)
    @body['token']  = token
  end  

  def register(token)
    set_language_if_valid(token.user.language)
    @recipients     = token.user.mail
    @from           = Setting.mail_from
    @subject        = l(:mail_subject_register)
    @body['token']  = token
  end
  
  def message_posted(message, recipients)
    set_language_if_valid(Setting.default_language)
    @recipients     = recipients
    @from           = Setting.mail_from
    @subject        = "[#{message.board.project.name} - #{message.board.name}] #{message.subject}"
    @body['message'] = message
  end
end
