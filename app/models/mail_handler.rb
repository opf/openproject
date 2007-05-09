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
  
  # Processes incoming emails
  # Currently, it only supports adding notes to an existing issue
  # by replying to the initial notification message
  def receive(email)
    # find related issue by parsing the subject
    m = email.subject.match %r{\[.*#(\d+)\]}
    return unless m
    issue = Issue.find_by_id(m[1])
    return unless issue
    
    # find user
    user = User.find_active(:first, :conditions => {:mail => email.from.first})
    return unless user
    # check permission
    return unless Permission.allowed_to_role("issues/add_note", user.role_for_project(issue.project))
    
    # add the notes
    issue.init_journal(user, email.body)
    issue.save
  end
end
