#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

module Notifications::CreateFromModelService::DocumentStrategy
  def self.reasons
    %i(subscribed)
  end

  def self.permission
    :view_documents
  end

  def self.supports_ian?(_reason)
    false
  end

  def self.supports_mail_digest?(_reason)
    false
  end

  def self.supports_mail?(_reason)
    true
  end

  def self.subscribed_users(journal)
    User.notified_globally subscribed_notification_reason(journal)
  end

  def self.subscribed_notification_reason(_journal)
    NotificationSetting::DOCUMENT_ADDED
  end

  def self.project(journal)
    journal.data.project
  end

  def self.user(journal)
    journal.user
  end
end
