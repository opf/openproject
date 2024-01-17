#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Timestamp
  ALLOWED_DATE_KEYWORDS = ["oneDayAgo", "lastWorkingDay", "oneWeekAgo", "oneMonthAgo"].freeze

  delegate :hash, to: :to_s

  class Exception < StandardError; end

  class TimestampParser
    DURATION_REGEX = /[+-]?P/ # ISO8601 "Period"

    DATE_KEYWORD_REGEX =
      %r{
        ^(?:#{ALLOWED_DATE_KEYWORDS.join('|')}) # match the relative date keyword
        @(?:([0-1]?[0-9]|2[0-3]):[0-5]?[0-9]) # match the hour part
          [+-](?:([0-1]?[0-9]|2[0-3]):[0-5]?[0-9])$ # match the timezone offset
      }x

    def initialize(string)
      @original_string = string
    end

    def parse!
      @timestamp_string = self.class.substitute_special_shortcut_values(@original_string)

      case @timestamp_string
      when DURATION_REGEX
        ActiveSupport::Duration.parse(@timestamp_string).iso8601
      when DATE_KEYWORD_REGEX # Built in date keywords
        @timestamp_string
      else
        DateTime.iso8601(@timestamp_string).iso8601
      end
    rescue ArgumentError => e
      raise e.class, "The string \"#{@original_string}\" cannot be parsed to a Timestamp."
    end

    class << self
      def substitute_special_shortcut_values(string)
        # map now to PT0S
        return 'PT0S' if string == 'now'

        # map 1y to P1Y, 1m to P1M, 1w to P1W, 1d to P1D
        # map -1y to P-1Y, -1m to P-1M, -1w to P-1W, -1d to P-1D
        # map -1y1d to P-1Y-1D
        units = ['y', 'm', 'w', 'd']
        sign = '-' if string.start_with?('-')
        substitutions = units.filter_map { |unit| string.scan(/\d+#{unit}/).first&.upcase }

        return string if substitutions.empty?

        "P#{sign}#{substitutions.join(sign)}"
      end
    end
  end

  class << self
    def parse(timestamp_string)
      return timestamp_string if timestamp_string.is_a?(Timestamp)

      timestamp_string = timestamp_string.strip
      TimestampParser.new(timestamp_string).parse!
      new(timestamp_string)
    end

    # Take a comma-separated string of ISO-8601 timestamps and convert it
    # into an array of Timestamp objects.
    #
    def parse_multiple(comma_separated_timestamp_string)
      comma_separated_timestamp_string.to_s.split(",").compact_blank.collect do |timestamp_string|
        Timestamp.parse(timestamp_string)
      end
    end

    def now
      new(ActiveSupport::Duration.build(0).iso8601)
    end

    def allowed(timestamps)
      return timestamps if EnterpriseToken.allows_to?(:baseline_comparison)

      timestamps.select { |t| t.one_day_ago? || t.to_time >= Date.yesterday }
    end
  end

  def initialize(arg = Timestamp.now.to_s)
    if arg.is_a? String
      @timestamp_string = TimestampParser.substitute_special_shortcut_values(arg)
    elsif arg.respond_to? :iso8601
      @timestamp_string = arg.iso8601
    else
      raise Timestamp::Exception,
            "Argument type not supported. " \
            "Please provide an ISO-8601 or a relative date keyword String, or anything that responds to :iso8601, e.g. a Time."
    end
  end

  def relative?
    duration? || relative_date_keyword?
  end

  def duration?
    to_s.match? TimestampParser::DURATION_REGEX
  end

  def relative_date_keyword?
    to_s.match? TimestampParser::DATE_KEYWORD_REGEX
  end

  def one_day_ago?
    to_s.start_with? 'oneDayAgo'
  end

  def to_s
    @timestamp_string.to_s
  end

  def to_str
    to_s
  end

  def inspect
    "#<Timestamp \"#{self}\">"
  end

  def absolute
    Timestamp.new(to_time)
  end

  def to_time
    if duration?
      Time.zone.now - to_duration.abs
    elsif relative_date_keyword?
      relative_date_keyword_to_time
    else
      Time.zone.parse(self)
    end
  end

  def to_duration
    if duration?
      ActiveSupport::Duration.parse(self)
    else
      raise Timestamp::Exception, "This timestamp does not contain a duration cannot be represented as ActiveSupport::Duration."
    end
  end

  def relative_date_keyword_to_time
    unless relative_date_keyword?
      raise ArgumentError, "This timestamp does not contain a relative date keyword and cannot be represented as Time."
    end

    relative_date_keyword, time_part = @timestamp_string.split('@')

    date = case relative_date_keyword
           when 'oneDayAgo'      then 1.day.ago
           when 'lastWorkingDay' then Day.last_working.date || 1.day.ago
           when 'oneWeekAgo'     then 1.week.ago
           when 'oneMonthAgo'    then 1.month.ago
           end

    Time.zone.parse(time_part, date)
  end

  def as_json(*_args)
    to_s
  end

  def to_json(*_args)
    to_s
  end

  def ==(other)
    case other
    when String
      to_s == other
    when Timestamp
      to_s == other.to_s
    when NilClass
      to_s.blank?
    else
      raise Timestamp::Exception, "Comparison to #{other.class.name} not implemented, yet."
    end
  end

  def eql?(other)
    self == other
  end

  def historic?
    self != Timestamp.now
  end

  def valid?
    TimestampParser.new(to_s).parse!
  rescue StandardError
    false
  end
end
