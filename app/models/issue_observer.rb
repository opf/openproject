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

class IssueObserver < ActiveRecord::Observer
  attr_accessor :send_notification
  
  def after_create(issue)
    if self.send_notification
      Mailer.deliver_issue_add(issue) if Setting.notified_events.include?('issue_added')
    end
    clear_notification
  end
  
  # Wrap send_notification so it defaults to true, when it's nil
  def send_notification
    return true if @send_notification.nil?
    return @send_notification
  end
  
  private

  # Need to clear the notification setting after each usage otherwise it might be cached
  def clear_notification
    @send_notification = true
  end
end
