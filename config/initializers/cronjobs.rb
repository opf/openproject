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

# Register "Cron-like jobs"
Rails.application.config.after_initialize do
  Rails.application.config.good_job.cron.merge!(
    {
      "Cron::ClearOldSessionsJob": {
        cron: "15 1 * * *", # runs at 1:15 nightly
        class: Cron::ClearOldSessionsJob.name
      },
      "Cron::ClearTmpCacheJob": {
        cron: "45 2 * * 7", # runs at 02:45 sundays
        class: Cron::ClearTmpCacheJob.name
      },
      "Cron::ClearUploadedFilesJob": {
        cron: "0 23 * * 5", # runs 23:00 fridays
        class: Cron::ClearUploadedFilesJob.name
      },
      "OAuth::CleanupJob": {
        cron: "52 1 * * *",
        class: OAuth::CleanupJob.name
      },
      "PaperTrailAudits::CleanupJob": {
        cron: "3 4 * * 6",
        class: PaperTrailAudits::CleanupJob.name
      },
      "Attachments::CleanupUncontaineredJob": {
        cron: "03 22 * * *",
        class: Attachments::CleanupUncontaineredJob.name
      },
      "Notifications::ScheduleDateAlertsNotificationsJob": {
        cron: "*/15 * * * *",
        class: Notifications::ScheduleDateAlertsNotificationsJob.name
      },
      "Notifications::ScheduleReminderMailsJob": {
        cron: "*/15 * * * *",
        class: Notifications::ScheduleReminderMailsJob.name
      },
      "Ldap::SynchronizationJob": {
        cron: "30 23 * * *",
        class: Ldap::SynchronizationJob.name
      }
    }
  )
end
