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

module CostReports
  # Cost reports used to keep the filters a user was looking at in the session,
  # which made them leak between projects and browser tabs. They live on the URL
  # now, so a session left over from before is translated once and discarded.
  class SessionFilters
    KEY = :cost_query

    def initialize(session)
      @session = session
    end

    def any?
      stored.present? && (stored[:filters].present? || stored[:groups].present?)
    end

    def take!
      params = filters.to_params

      @session.delete(KEY)

      params
    end

    private

    def stored
      @session[KEY]
    end

    def filters
      CompactFilters.new(operators: stored.dig(:filters, :operators),
                        values: stored.dig(:filters, :values),
                        rows: stored.dig(:groups, :rows),
                        columns: stored.dig(:groups, :columns))
    end
  end
end
