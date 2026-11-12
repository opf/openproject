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

class WeekDay
  DAY_RANGE = Array(1..7)

  attr_accessor :day

  class << self
    def find_by!(day:)
      raise ActiveRecord::RecordNotFound, "Couldn't find WeekDay with day #{day}" unless day.in?(DAY_RANGE)

      new(day:)
    end

    def all
      DAY_RANGE.map do |day|
        new(day:)
      end
    end
  end

  def initialize(day:)
    self.day = day
  end

  def name
    day_names = I18n.t("date.day_names")
    day_names[day % 7]
  end

  def working
    Setting.working_days.empty? || day.in?(Setting.working_days)
  end
end
