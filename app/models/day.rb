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

class Day < ApplicationRecord
  include Tableless

  has_many :non_working_days,
           inverse_of: false,
           class_name: "NonWorkingDay",
           foreign_key: :date,
           primary_key: :date,
           dependent: nil

  attribute :date, :date, default: nil
  attribute :day_of_week, :integer, default: nil
  attribute :working, :boolean, default: "t"

  delegate :name, to: :week_day, allow_nil: true

  scope :working, -> { where(working: true) }

  def self.default_scope
    today = Time.zone.today
    from = today.at_beginning_of_month
    to = today.next_month.at_end_of_month
    from_range(from:, to:)
    .includes(:non_working_days)
    .order("days.id")
  end

  def self.from_range(from:, to:)
    from(Arel.sql(from_sql(from:, to:)))
  end

  def self.from_sql(from:, to:)
    from = from.to_date
    to = to.to_date
    <<~SQL.squish
      (SELECT
        to_char(dd, 'YYYYMMDD')::integer id,
        date_trunc('day', dd)::date date,
        extract(isodow from dd) day_of_week,
        (COALESCE(POSITION(extract(isodow from dd)::text IN settings.value) > 0, TRUE)
          AND non_working_days.id IS NULL)::bool working
      FROM
      generate_series( '#{from}'::timestamp,
            '#{to}'::timestamp,
            '1 day'::interval) dd
      LEFT JOIN settings
           ON settings.name = 'working_days'
      LEFT JOIN non_working_days
           ON dd = non_working_days.date
      ) days
    SQL
  end

  def self.last_working
    # Look up only from 8 days ago, because the Setting.working_days must have at least 1 working weekday.
    from_range(from: 8.days.ago, to: Time.zone.yesterday).where(working: true).last
  end

  def week_day
    WeekDay.new(day: day_of_week)
  end
end
