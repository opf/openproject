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

class NotificationSetting < ApplicationRecord
  WATCHED = :watched
  ASSIGNEE = :assignee
  RESPONSIBLE = :responsible
  MENTIONED = :mentioned
  SHARED = :shared
  START_DATE = :start_date
  DUE_DATE = :due_date
  OVERDUE = :overdue
  WORK_PACKAGE_CREATED = :work_package_created
  WORK_PACKAGE_COMMENTED = :work_package_commented
  WORK_PACKAGE_PROCESSED = :work_package_processed
  WORK_PACKAGE_PRIORITIZED = :work_package_prioritized
  WORK_PACKAGE_SCHEDULED = :work_package_scheduled
  NEWS_ADDED = :news_added
  NEWS_COMMENTED = :news_commented
  DOCUMENT_ADDED = :document_added
  FORUM_MESSAGES = :forum_messages
  WIKI_PAGE_ADDED = :wiki_page_added
  WIKI_PAGE_UPDATED = :wiki_page_updated
  MEMBERSHIP_ADDED = :membership_added
  MEMBERSHIP_UPDATED = :membership_updated

  def self.all_settings
    [
      WATCHED,
      ASSIGNEE,
      RESPONSIBLE,
      MENTIONED,
      SHARED,
      WORK_PACKAGE_CREATED,
      WORK_PACKAGE_COMMENTED,
      WORK_PACKAGE_PROCESSED,
      WORK_PACKAGE_PRIORITIZED,
      WORK_PACKAGE_SCHEDULED,
      *date_alert_settings,
      *email_settings
    ]
  end

  def self.non_participating_settings
    [
      WORK_PACKAGE_CREATED,
      WORK_PACKAGE_COMMENTED,
      WORK_PACKAGE_PROCESSED,
      WORK_PACKAGE_PRIORITIZED,
      WORK_PACKAGE_SCHEDULED
    ]
  end

  def self.date_alert_settings
    [
      START_DATE,
      DUE_DATE,
      OVERDUE
    ]
  end

  def self.email_settings
    [
      NEWS_ADDED,
      NEWS_COMMENTED,
      DOCUMENT_ADDED,
      FORUM_MESSAGES,
      WIKI_PAGE_ADDED,
      WIKI_PAGE_UPDATED,
      MEMBERSHIP_ADDED,
      MEMBERSHIP_UPDATED
    ]
  end

  belongs_to :project, optional: true
  belongs_to :user

  include Scopes::Scoped
  scopes :applicable

  # rubocop:disable Naming/PredicateMethod
  def start_date_active
    start_date.present?
  end

  def due_date_active
    due_date.present?
  end

  def overdue_active
    overdue.present?
  end
  # rubocop:enable Naming/PredicateMethod
end
