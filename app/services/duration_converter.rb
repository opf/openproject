# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2024 the OpenProject GmbH
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
# ++

# We use BigDecimal to handle floating point arithmetic and avoid
# weird floating point results on decimal operations when converting
# hours to seconds on duration outputting.
require "bigdecimal"

class DurationConverter
  class << self
    def parse(duration_string)
      # Keep 0 values and convert the extracted duration to hours
      # by dividing by 3600.
      ChronicDuration.parse(duration_string, keep_zero: true, default_unit: "hours") / 3600.to_f
    end

    def output(duration_in_hours)
      return duration_in_hours if duration_in_hours.nil?

      duration_in_seconds = convert_duration_to_seconds(duration_in_hours)

      # return "0 h" if parsing 0.
      # ChronicDuration returns nil when parsing 0.
      # By default, its unit is seconds and if we were
      # keeping zeroes, we'd format this as "0 secs".
      #
      # We want to override this behavior.
      if ChronicDuration.output(duration_in_seconds, default_unit: "hours").nil?
        "0h"
      else
        ChronicDuration.output(duration_in_seconds, default_unit: "hours", format: :short)
      end
    end

    private

    def convert_duration_to_seconds(duration_in_hours)
      (BigDecimal(duration_in_hours.to_s) * 3600).to_f
    end
  end
end
