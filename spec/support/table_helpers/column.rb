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

require_relative "identifier"
require_relative "column_type/generic"
require_relative "column_type/with_identifier_metadata"
require_relative "column_type/duration"
require_relative "column_type/hierarchy"
require_relative "column_type/percentage"
require_relative "column_type/status"
require_relative "column_type/subject"

module TableHelpers
  class Column
    extend Identifier

    COLUMN_TYPES = {
      estimated_hours: ColumnType::Duration,
      derived_estimated_hours: ColumnType::Duration,
      remaining_hours: ColumnType::Duration,
      derived_remaining_hours: ColumnType::Duration,
      done_ratio: ColumnType::Percentage,
      derived_done_ratio: ColumnType::Percentage,
      hierarchy: ColumnType::Hierarchy,
      status: ColumnType::Status,
      subject: ColumnType::Subject,
      __fallback__: ColumnType::Generic
    }.freeze

    def self.for(header)
      new(header:, attribute: attribute_for(header))
    end

    def self.attribute_for(header)
      case header
      when /\A\s*estimated hours/i
        raise ArgumentError, 'Please use "work" instead of "estimated hours"'
      when /derived estimated hours/i
        raise ArgumentError, 'Please use "∑ work" instead of "derived estimated hours"'
      when /\A\s*remaining hours/i
        raise ArgumentError, 'Please use "remaining work" instead of "remaining hours"'
      when /derived remaining hours/i
        raise ArgumentError, 'Please use "∑ remaining work" instead of "derived remaining hours"'
      when /\A\s*work/i
        :estimated_hours
      when /(∑|derived|total) work/i
        :derived_estimated_hours
      when /\A\s*remaining work/i
        :remaining_hours
      when /(∑|derived|total) remaining work/i
        :derived_remaining_hours
      when /\A\s*% complete/i
        :done_ratio
      when /(∑|derived|total) % complete/i
        :derived_done_ratio
      when /end date/i
        :due_date
      when /status/, /hierarchy/
        to_identifier(header)
      else
        attribute = to_identifier(header)
        assert_work_package_attribute_exists(attribute)
        attribute
      end
    end

    attr_reader :attribute, :raw_header, :title

    def initialize(header:, attribute:)
      @raw_header = header
      @title = header.strip
      @attribute = attribute
    end

    def column_type
      @column_type ||= COLUMN_TYPES.fetch(attribute, COLUMN_TYPES[:__fallback__]).new
    end

    delegate :format, :cell_format, to: :column_type

    def attributes_for_work_package(work_package)
      column_type.attributes_for_work_package(attribute, work_package)
    end

    def read_and_update_work_packages_data(work_packages_data)
      work_packages_data.each do |work_package_data|
        work_package_data.deep_merge!(
          column_type.extract_data(attribute, raw_header, work_package_data, work_packages_data)
        )
      end
    end

    def self.assert_work_package_attribute_exists(attribute)
      return if WorkPackage.attribute_names.include?(attribute.to_s)

      raise ArgumentError, "WorkPackage does not have an attribute named #{attribute.inspect}"
    end
  end
end
