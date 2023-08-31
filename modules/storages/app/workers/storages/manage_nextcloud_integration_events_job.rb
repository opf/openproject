#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class Storages::ManageNextcloudIntegrationEventsJob < ApplicationJob
  DEBOUNCE_TIME = 5.seconds.freeze

  queue_with_priority :above_normal

  def self.debounce
    count = Delayed::Job
              .where("handler LIKE ?", "%job_class: #{self}%")
              .where(locked_at: nil)
              .where('run_at <= ?', DEBOUNCE_TIME.from_now)
              .delete_all
    Rails.logger.info("deleted: #{count} jobs")
    set(wait: DEBOUNCE_TIME).perform_later
  end

  def perform
    result = Storages::NextcloudStorage.sync_all_group_folders
    self.class.debounce if result == false
  end
end
