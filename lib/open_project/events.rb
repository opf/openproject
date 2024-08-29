# frozen_string_literal: true

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

module OpenProject
  ##
  # Events defined in OpenProject, e.g. created work packages.
  # The module defines a constant for each event.
  #
  # Plugins should register their events here too by prepending a module
  # including the respective constants.
  #
  # @note Does not include all events but it should!
  # @see OpenProject::Notifications
  module Events
    AGGREGATED_WORK_PACKAGE_JOURNAL_READY = "aggregated_work_package_journal_ready"
    AGGREGATED_WIKI_JOURNAL_READY = "aggregated_wiki_journal_ready"
    AGGREGATED_NEWS_JOURNAL_READY = "aggregated_news_journal_ready"
    AGGREGATED_MESSAGE_JOURNAL_READY = "aggregated_message_journal_ready"

    ATTACHMENT_CREATED = "attachment_created"

    JOURNAL_CREATED = "journal_created"

    MEMBER_CREATED = "member_created"
    MEMBER_UPDATED = "member_updated"
    MEMBER_DESTROYED = "member_destroyed"

    OAUTH_CLIENT_TOKEN_CREATED = "oauth_client_token_created"

    TIME_ENTRY_CREATED = "time_entry_created"

    NEWS_COMMENT_CREATED = "news_comment_created"

    PROJECT_CREATED = "project_created"
    PROJECT_UPDATED = "project_updated"
    PROJECT_RENAMED = "project_renamed"
    PROJECT_ARCHIVED = "project_archived"
    PROJECT_UNARCHIVED = "project_unarchived"

    PROJECT_STORAGE_CREATED = "project_storage_created"
    PROJECT_STORAGE_UPDATED = "project_storage_updated"
    PROJECT_STORAGE_DESTROYED = "project_storage_destroyed"

    STORAGE_TURNED_UNHEALTHY = "storage_turned_unhealthy"
    STORAGE_TURNED_HEALTHY = "storage_turned_healthy"

    REMOTE_IDENTITY_CREATED = "remote_identity_created"

    ROLE_UPDATED = "role_updated"
    ROLE_DESTROYED = "role_destroyed"

    WATCHER_ADDED = "watcher_added"
    WATCHER_DESTROYED = "watcher_destroyed"

    WORK_PACKAGE_SHARED = "work_package_shared"
  end
end
