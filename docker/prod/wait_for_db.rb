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

require "timeout"

timeout = (ENV["WAIT_FOR_DB_TIMEOUT_SECONDS"] || 120).to_i

Timeout::timeout(timeout) do
  loop do
    puts "[#{DateTime.now}] waiting for db to be ready and migrated"
    sleep 4

    begin
      ActiveRecord::Migration.check_all_pending!

      puts "[#{DateTime.now}] db ready"
      exit 0
    rescue StandardError => e
      puts "[#{DateTime.now}] not ready yet: #{e.message}"
    end
  end
end
