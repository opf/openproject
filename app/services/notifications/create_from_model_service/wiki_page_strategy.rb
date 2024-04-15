#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Notifications::CreateFromModelService::WikiPageStrategy
  def self.reasons
    %i(watched subscribed)
  end

  def self.permission
    :view_wiki_pages
  end

  def self.supports_ian?
    false
  end

  def self.supports_mail_digest?
    false
  end

  def self.supports_mail?
    true
  end

  def self.subscribed_users(journal)
    User.notified_globally subscribed_notification_reason(journal)
  end

  def self.subscribed_notification_reason(journal)
    if journal.initial?
      NotificationSetting::WIKI_PAGE_ADDED
    else
      NotificationSetting::WIKI_PAGE_UPDATED
    end
  end

  def self.watcher_users(journal)
    page = journal.journable

    if journal.initial?
      User.watcher_recipients(page.wiki)
    else
      User.watcher_recipients(page.wiki)
          .or(User.watcher_recipients(page))
    end
  end

  def self.project(journal)
    journal.data.project
  end

  def self.user(journal)
    journal.user
  end
end
