#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

OpenProject::Notifications.subscribe(OpenProject::Events::JOURNAL_CREATED) do |payload|
  Notifications::JournalNotificationService.call(payload[:journal], payload[:send_notification])
end

OpenProject::Notifications.subscribe(OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY) do |payload|
  Notifications::JournalWpMailService.call(payload[:journal], payload[:send_mail])
end

OpenProject::Notifications.subscribe(OpenProject::Events::AGGREGATED_WIKI_JOURNAL_READY) do |payload|
  Notifications::JournalWikiMailService.call(payload[:journal], payload[:send_mail])
end

OpenProject::Notifications.subscribe(OpenProject::Events::WATCHER_ADDED) do |payload|
  WatcherAddedNotificationMailer.handle_watcher(payload[:watcher], payload[:watcher_setter])
end

OpenProject::Notifications.subscribe(OpenProject::Events::WATCHER_REMOVED) do |payload|
  WatcherRemovedNotificationMailer.handle_watcher(payload[:watcher], payload[:watcher_remover])
end

OpenProject::Notifications.subscribe(OpenProject::Events::MEMBER_CREATED) do |payload|
  Mails::Deliver::MemberCreatedJob
    .perform_later(current_user: User.current,
                   member: payload[:member])
end

OpenProject::Notifications.subscribe(OpenProject::Events::MEMBER_UPDATED) do |payload|
  Mails::Deliver::MemberUpdatedJob
    .perform_later(current_user: User.current,
                   member: payload[:member])
end
