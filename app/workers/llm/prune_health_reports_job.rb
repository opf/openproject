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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Llm
  # Keeps the health report history bounded.
  #
  # Until the scheduled check existed, health_reports only grew when somebody
  # clicked "Run checks", so nothing anywhere pruned the table. A four-times-daily
  # writer changes that, and this is the first pruner it has had.
  #
  # Only ever prunes reports belonging to an LLM connection: storages and wikis
  # share the table and still write a row only on demand.
  class PruneHealthReportsJob < ApplicationJob
    # Enough history to see a pattern in when a flaky server fails, without
    # keeping a year of identical green reports.
    KEEP = 50
    MAX_AGE = 90.days

    queue_with_priority :low

    def perform
      LlmConnection.find_each do |connection|
        recent = connection.health_reports.order(created_at: :desc).limit(KEEP).pluck(:id)

        connection.health_reports
                  .where.not(id: recent)
                  .where(created_at: ...MAX_AGE.ago)
                  .delete_all
      end
    end
  end
end
