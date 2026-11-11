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

module Sprints::Scopes::Preceding
  extend ActiveSupport::Concern

  class_methods do
    # The +limit+ sprints listed closest before +sprint+ in date order, handed back in that order.
    # +order_by_date+ is relied upon for the order.
    def preceding(sprint, limit:)
      nearest = unscoped.from("preceding_candidates")
                        .select("id")
                        .where("position < (SELECT position FROM preceding_candidates WHERE id = ?)", sprint.id)
                        .order(Arel.sql("position DESC"))
                        .limit(limit)

      # numbered_by_date will receive other scopes chained when calling this method
      # (e.g. `Sprint.for_project(...).preceding(...)`).
      with(preceding_candidates: numbered_by_date).where(id: nearest).order_by_date
    end

    private

    def numbered_by_date
      by_date = unscoped.order_by_date.arel.orders.map(&:to_sql).join(", ")

      select(:id, Arel.sql("ROW_NUMBER() OVER (ORDER BY #{by_date}) AS position"))
    end
  end
end
