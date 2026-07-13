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

if Rails.env.production?
  config = Rails.application.config.database_configuration[Rails.env]
  pool_size = config && [OpenProject::Configuration.web_max_threads + 1, config["pool"].to_i].max

  # make sure we have enough connections in the pool for each thread and then some
  if pool_size && pool_size > ActiveRecord::Base.connection_pool.size
    Rails.logger.info { "Increasing database pool size to #{pool_size} to match max threads" }

    ActiveRecord::Base.establish_connection config.merge(pool: pool_size)
  end
end

# Log a warning if we encounter an under-provisioned dev setup
if Rails.env.local?
  utility_connections = 1 + GoodJob::SharedExecutor::MAX_THREADS # based on GoodJob documentation
  required_pool_size = OpenProject::Configuration.web_max_threads +
                       OpenProject::Configuration.good_job_max_threads +
                       utility_connections

  if ActiveRecord::Base.connection_pool.size < required_pool_size
    Rails.logger.warn do
      "DB pool size of #{ActiveRecord::Base.connection_pool.size} is too small and could cause problems. " \
        "The recommended sizing is at least #{required_pool_size} " \
        "(#{OpenProject::Configuration.web_max_threads} for web_max_threads + " \
        "#{OpenProject::Configuration.good_job_max_threads} for web_max_threads + " \
        "#{utility_connections} for GoodJob utility connections). " \
        "Please adjust the pool parameter in database.yml or \"?pool=N\" parameter in DATABASE_URL."
    end
  end
end
