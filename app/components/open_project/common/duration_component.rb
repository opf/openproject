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

module OpenProject
  module Common
    class DurationComponent < Primer::Component
      VALID_TYPES = %i[seconds minutes hours days weeks months years].freeze
      attr_reader :duration, :abbreviated, :separator

      def initialize(duration, type = :seconds, separator: ", ", abbreviated: false, **args)
        super

        @duration = parse_duration(duration, type)
        @abbreviated = abbreviated
        @separator = separator
        @system_arguments = args
      end

      def call
        render(Primer::Beta::Text.new) { text }
      end

      def text
        localized_parts.join(separator)
      end

      private

      def localized_parts
        duration.parts.map do |fragment, count|
          abbreviated_key = "datetime.distance_in_words.x_#{fragment}_abbreviated"
          key = "datetime.distance_in_words.x_#{fragment}"

          if abbreviated && I18n.exists?(abbreviated_key)
            I18n.t(abbreviated_key, count:)
          else
            I18n.t(key, count:)
          end
        end
      end

      def parse_duration(duration, type)
        case duration
        when ActiveSupport::Duration
          parse_number(duration.to_i, :seconds)
        when Numeric
          parse_number(duration, type)
        when String
          ActiveSupport::Duration.parse(duration)
        else
          raise ArgumentError, "Invalid duration type #{duration.class}."
        end
      end

      def parse_number(duration, type)
        if type.nil? || VALID_TYPES.exclude?(type.to_sym)
          raise ArgumentError, "Provide known type (#{VALID_TYPES.join(', ')}) when providing a number to this component."
        end

        ActiveSupport::Duration.build(duration.send(type))
      end
    end
  end
end
