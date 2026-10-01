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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module My
  module Reminders
    class DailyTimesComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(times:, scope:)
        super

        @times = Array(times)
        @scope = scope
      end

      def field_name
        "#{@scope}[times][]"
      end

      def time_options
        (0..23).map do |hour|
          time = Time.utc(2000, 1, 1, hour)
          [I18n.l(time, format: :time), time.strftime("%H:00:00+00:00")]
        end
      end

      def selected_value_for(time_str)
        Time.zone.parse(time_str.to_s).strftime("%H:00:00+00:00")
      end
    end
  end
end
