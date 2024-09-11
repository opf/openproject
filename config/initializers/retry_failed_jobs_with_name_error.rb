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

Rails.application.configure do
  config.after_initialize do
    # Retry jobs that failed with "NameError: uninitialized constant ...Job" as
    # the worker may have failed to load it because the job class did not exist
    # at the time of execution. This can happen on upgrades when the worker is
    # still running the previous version while a migration is enqueuing jobs defined
    # in the new version.
    #
    # Once the migration is over and the worker gets restarted, the job will be
    # retried thanks to this piece of code below.
    GoodJob::Job
      .discarded
      .where("error LIKE ?", "NameError: uninitialized constant %Job")
      .find_each do |job|
        job.retry_job
        Rails.logger.info("Successfully enqueued job for retry #{job.display_name} (job id: #{job.id})")
      rescue StandardError => e
        Rails.logger.error("Failed to enqueue job for retry #{job.display_name} (job id: #{job.id}): #{e.message}")
      end
  rescue ActiveRecord::StatementInvalid
    # will happen when we currently are migrating
  rescue LoadError
    # Ignore LoadError that happens when nulldb://db database adapter is used
  end
end
