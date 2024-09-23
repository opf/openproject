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

module TableHelpers
  module Column
    extend Identifier

    def self.for(header)
      case header
      when /\A\s*estimated hours/i
        raise ArgumentError, 'Please use "work" instead of "estimated hours"'
      when /derived estimated hours/i
        raise ArgumentError, 'Please use "derived work" instead of "derived estimated hours"'
      when /derived remaining hours/i
        raise ArgumentError, 'Please use "derived remaining work" instead of "derived remaining hours"'
      when /\A\s*remaining hours/i
        raise ArgumentError, 'Please use "remaining work" instead of "remaining hours"'
      when /\A\s*work/i
        Duration.new(header:, attribute: :estimated_hours)
      when /(∑|derived|total) work/i
        Duration.new(header:, attribute: :derived_estimated_hours)
      when /\A\s*remaining work/i
        Duration.new(header:, attribute: :remaining_hours)
      when /(∑|derived|total) remaining work/i
        Duration.new(header:, attribute: :derived_remaining_hours)
      when /\A\s*% complete/i
        Percentage.new(header:, attribute: :done_ratio)
      when /(∑|derived|total) % complete/i
        Percentage.new(header:, attribute: :derived_done_ratio)
      when /end date/i
        Generic.new(header:, attribute: :due_date)
      when /status/
        Status.new(header:)
      when /subject/
        Subject.new(header:)
      when /hierarchy/
        Hierarchy.new(header:)
      else
        assert_work_package_attribute_exists(header)
        Generic.new(header:)
      end
    end

    def self.assert_work_package_attribute_exists(attribute)
      attribute = to_identifier(attribute).to_s
      return if WorkPackage.attribute_names.include?(attribute)

      raise ArgumentError, "WorkPackage does not have an attribute named #{attribute.inspect}"
    end

    class Generic
      include Identifier

      attr_reader :attribute, :title, :raw_header

      def initialize(header:, attribute: nil)
        @raw_header = header
        @title = header.strip
        @attribute = attribute || to_identifier(title)
      end

      def format(value)
        value.to_s
      end

      def cell_format(value, size)
        format(value).send(text_align, size)
      end

      def parse(raw_value)
        raw_value.strip
      end

      def text_align
        :ljust
      end

      def attribute_value_for(work_package)
        work_package.read_attribute(attribute)
      end

      def read_and_update_work_packages_data(work_packages_data)
        work_packages_data.each do |work_package_data|
          work_package_data => { attributes:, row: }
          raw_value = row[raw_header]
          work_package_data.merge!(metadata_for_value(raw_value))
          attributes.merge!(attributes_for_raw_value(raw_value, work_package_data, work_packages_data))
        end
      end

      def attributes_for_work_package(work_package)
        { attribute => work_package.read_attribute(attribute) }
      end

      def attributes_for_raw_value(raw_value, _data, _work_packages_data)
        { attribute => parse(raw_value) }
      end

      def metadata_for_value(_raw_value)
        {}
      end
    end

    module WithIdentifierMetadata
      include Identifier

      def metadata_for_value(raw_value, *)
        super.merge(identifier: to_identifier(raw_value))
      end
    end

    class Duration < Generic
      def text_align
        :rjust
      end

      def format(value)
        if value.nil?
          ""
        elsif value == value.truncate
          "%sh" % value.to_i
        else
          "%sh" % value
        end
      end

      def parse(raw_value)
        raw_value.blank? ? nil : raw_value.to_f
      end
    end

    class Percentage < Generic
      def text_align
        :rjust
      end

      def format(value)
        if value.nil?
          ""
        else
          "%s%%" % value.to_i
        end
      end

      def parse(raw_value)
        raw_value.blank? ? nil : raw_value.to_i
      end
    end

    class Status < Generic
      def attributes_for_work_package(work_package)
        { status: work_package.status.name }
      end
    end

    class Subject < Generic
      include WithIdentifierMetadata
    end

    class Hierarchy < Generic
      include WithIdentifierMetadata

      def attributes_for_work_package(work_package)
        {
          parent: to_identifier(work_package.parent&.subject),
          subject: work_package.subject
        }
      end

      def attributes_for_raw_value(raw_value, data, work_packages_data)
        {
          parent: find_parent(data, work_packages_data),
          subject: parse(raw_value)
        }
      end

      def metadata_for_value(raw_value)
        super.merge(hierarchy_indent: raw_value[/\A */].size)
      end

      private

      def find_parent(data, work_packages_data)
        return if data[:hierarchy_indent] == 0

        work_packages_data
            .slice(0, data[:index])
            .reverse
            .find { _1[:hierarchy_indent] < data[:hierarchy_indent] }
            .then { _1&.fetch(:identifier) }
      end
    end
  end
end
