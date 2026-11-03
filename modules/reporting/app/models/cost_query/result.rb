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

class CostQuery::Result < Report::Result
  module BaseAdditions
    def inspect
      "<##{self.class}: @fields=#{fields.inspect} @type=#{type.inspect} " \
        "@size=#{size} @count=#{count} @units=#{units} @real_costs=#{real_costs}>"
    end

    def display_costs?
      display_costs > 0
    end
  end

  class Base < Report::Result::Base
    include BaseAdditions
  end

  class DirectResult < Report::Result::DirectResult
    include BaseAdditions

    def display_costs
      self["display_costs"].to_i
    end

    def real_costs
      (self["real_costs"] || 0).to_d if display_costs? # FIXME: default value here?
    end

    def start_timestamp
      return nil if self["start_time"].blank? || self["time_zone"].blank? || self["spent_on"].blank?

      timestamp(self["spent_on"], self["start_time"], self["time_zone"])
    end

    def end_timestamp
      return nil if self["units"].blank?

      start = start_timestamp
      return nil if start.nil?

      start + self["units"].to_f.hours
    end

    def entity_gid
      "gid://#{GlobalID.app}/#{self['entity_type']}/#{self['entity_id']}"
    end

    private

    def timestamp(date, time, time_zone)
      ActiveSupport::TimeZone[time_zone].local(date.year, date.month, date.day, time / 60, time % 60)
    end
  end

  class WrappedResult < Report::Result::WrappedResult
    include BaseAdditions

    def display_costs
      (sum_for :display_costs) >= 1 ? 1 : 0
    end

    def real_costs
      sum_for :real_costs if display_costs?
    end
  end
end
