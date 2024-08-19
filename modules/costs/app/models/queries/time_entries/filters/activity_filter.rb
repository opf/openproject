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

class Queries::TimeEntries::Filters::ActivityFilter < Queries::TimeEntries::Filters::TimeEntryFilter
  def allowed_values
    # To mask the internal complexity of time entries and to
    # allow filtering by a combined value only shared activities are
    # valid values
    @allowed_values ||= ::TimeEntryActivity
      .shared
      .pluck(:name, :id)
  end

  def type
    :list_optional
  end

  def self.key
    :activity_id
  end

  def where
    # Because the project specific activity is used for storing the time entry,
    # we have to deduce the actual filter value which is the id of all the provided activities' children.
    # But when the activity itself is already shared, we use that value.
    db_values = child_values
                .or(shared_values)
                .pluck(:id)

    operator_strategy.sql_for_field(db_values, self.class.model.table_name, self.class.key)
  end

  private

  def child_values
    TimeEntryActivity
      .where(parent_id: values)
  end

  def shared_values
    TimeEntryActivity
      .shared
      .where(id: values)
  end
end
