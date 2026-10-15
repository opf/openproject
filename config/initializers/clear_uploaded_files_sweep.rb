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

require "concurrent/timer_task"

# CarrierWave cache directories live on the local tmp volume. Web and GoodJob
# processes each have their own volume, so both sweep it.
Rails.application.config.after_initialize do
  next unless GoodJob::CLI.within_exe? || defined?(Rails::Server)

  Concurrent::TimerTask.execute(execution_interval: 6.hours.to_i, run_now: false) do
    Rails.application.executor.wrap { Attachment.clean_cached_files!(age_in_seconds: 6.hours.to_i) }
  rescue StandardError => e
    Rails.logger.error "Failed to clean cached uploaded files: #{e.message}"
  end
end
