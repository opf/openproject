# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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
    # Sends to all project members
    @recipients     = issue.project.members.collect { |m| m.user.mail if m.user.mail_notification }
    @from           = $RDM_MAIL_FROM
    @subject        = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] #{issue.status.name} - #{issue.subject}"
    @body['issue']  = issue
  end

  def issue_edit(journal)
    # Sends to all project members
    issue = journal.journalized
    @recipients     = issue.project.members.collect { |m| m.user.mail if m.user.mail_notification }
    @from           = $RDM_MAIL_FROM
    @subject        = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] #{issue.status.name} - #{issue.subject}"
    @body['issue']  = issue
    @body['journal']= journal
  end
  
  def lost_password(token)
    @recipients     = token.user.mail
    @from           = $RDM_MAIL_FROM
    @subject        = l(:mail_subject_lost_password)
    @body['token']  = token
  end  

  def register(token)
    @recipients     = token.user.mail
    @from           = $RDM_MAIL_FROM
    @subject        = l(:mail_subject_register)
    @body['token']  = token
  end
end
