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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

Rails.application.configure do
  config.after_initialize do
    next if Rails.env.test?

    # Avoid running this on migrations or when the database is incomplete
    next if OpenProject::Database.migrations_pending?

    slow_sql_threshold = OpenProject::Configuration.sql_slow_query_threshold.to_i
    next if slow_sql_threshold == 0

    ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, start, finish, _id, data|
      # Skip transaction that may be blocked
      next if data[:sql].match?(/BEGIN|COMMIT/)

      # Skip tenant creation (load dump sql which is around 300kB)
      next if data[:sql][..120].include?("Dumped by pg_dump") || data[:sql].size > 200_000

      # Skip smaller durations
      duration = ((finish - start) * 1000).round(4)
      next if duration <= slow_sql_threshold

      payload = {
        duration:,
        time: start.iso8601,
        cached: !!data[:cache],
        sql: data[:sql]
      }

      sql_log_string = data[:sql].strip.gsub(/(^(\s+)?$\n)/, "")
      OpenProject.logger.warn "Encountered slow SQL (#{payload[:duration]} ms): #{sql_log_string}",
                              payload:,
                              # Hash of the query for reference/fingerprinting
                              reference: Digest::SHA1.hexdigest(data[:sql])
    rescue StandardError => e
      OpenProject.logger.error "Failed to record slow SQL query: #{e}"
    end
  end
end
