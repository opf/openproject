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
    if iso8601_string.start_with? "P" # ISO8601 "Period"
      ActiveSupport::Duration.parse(iso8601_string)
    elsif Time.zone.parse(iso8601_string).blank?
      raise ArgumentError, "The string \"#{iso8601_string}\" cannot be parsed to a Time."
    end
    Timestamp.new(iso8601_string)
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

  def inspect
    "#<Timestamp \"#{iso8601}\">"
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

  def as_json
    to_s
  end

  def to_json(*_args)
    to_s
  end

  def ==(other)
    iso8601 == other.iso8601
  end

  class Exception < StandardError; end
end
