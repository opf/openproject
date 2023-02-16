#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
  def initialize(arg = Timestamp.now.to_s)
    if arg.is_a? String
      @timestamp_iso8601_string = arg
    elsif arg.respond_to? :iso8601
      @timestamp_iso8601_string = arg.iso8601
    else
      raise Timestamp::Exception, \
            "Argument type not supported. " \
            "Please provide an ISO-8601 String or anything that responds to :iso8601, e.g. a Time."
    end
  end

  def self.parse(iso8601_string)
    return iso8601_string if iso8601_string.is_a?(Timestamp)

    iso8601_string.strip!
    iso8601_string = substitute_special_shortcut_values(iso8601_string)
    if iso8601_string.start_with? "P" # ISO8601 "Period"
      iso8601_string = ActiveSupport::Duration.parse(iso8601_string).iso8601
    elsif (time = Time.zone.parse(iso8601_string)).present?
      iso8601_string = time.iso8601
    else
      raise ArgumentError, "The string \"#{iso8601_string}\" cannot be parsed to Time or ActiveSupport::Duration."
    end
    Timestamp.new(iso8601_string)
  end

  # Take a comma-separated string of ISO-8601 timestamps and convert it
  # into an array of Timestamp objects.
  #
  def self.parse_multiple(comma_separated_iso8601_string)
    comma_separated_iso8601_string.to_s.split(",").compact_blank.collect do |iso8601_string|
      Timestamp.parse(iso8601_string)
    end
  end

  def self.now
    new(ActiveSupport::Duration.build(0).iso8601)
  end

  def relative?
    to_s.first == "P" # ISO8601 "Period"
  end

  def to_s
    iso8601
  end

  def to_str
    to_s
  end

  def iso8601
    @timestamp_iso8601_string.to_s
  end

  def to_iso8601
    iso8601
  end

  def inspect
    "#<Timestamp \"#{iso8601}\">"
  end

  def absolute
    Timestamp.new(to_time)
  end

  def to_time
    if relative?
      Time.zone.now - (to_duration * (to_duration.to_i.positive? ? 1 : -1))
    else
      Time.zone.parse(self)
    end
  end

  def to_duration
    if relative?
      ActiveSupport::Duration.parse(self)
    else
      raise Timestamp::Exception, "This timestamp is absolute and cannot be represented as ActiveSupport::Duration."
    end
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
      iso8601 == other or to_s == other
    when Timestamp
      iso8601 == other.iso8601
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

  class Exception < StandardError; end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity
  def self.substitute_special_shortcut_values(string)
    # map now to PT0S
    string = "PT0S" if string == "now"

    # map 1y to P1Y, 1m to P1M, 1w to P1W, 1d to P1D
    # map -1y to P-1Y, -1m to P-1M, -1w to P-1W, -1d to P-1D
    # map -1y1d to P-1Y-1D
    sign = "-" if string.start_with? "-"
    years = string.scan(/(\d+)y/).flatten.first
    months = string.scan(/(\d+)m/).flatten.first
    weeks = string.scan(/(\d+)w/).flatten.first
    days = string.scan(/(\d+)d/).flatten.first
    if years || months || weeks || days
      string = "P" \
               "#{sign if years}#{years}#{'Y' if years}" \
               "#{sign if months}#{months}#{'M' if months}" \
               "#{sign if weeks}#{weeks}#{'W' if weeks}" \
               "#{sign if days}#{days}#{'D' if days}"
    end

    string
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity
end
