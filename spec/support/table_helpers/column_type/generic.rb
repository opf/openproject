# frozen_string_literal: true

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

module TableHelpers
  module ColumnType
    class Generic
      def text_align
        :ljust
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

      # Extracts attributes data and metadata from the work package data read
      # from a table.
      def extract_data(attribute, raw_header, work_package_data, work_packages_data)
        raw_value = work_package_data.dig(:row, raw_header)

        {
          attributes: attributes_for_raw_value(attribute, raw_value, work_package_data, work_packages_data),
          **metadata_for_raw_value(raw_value)
        }
      end

      # Extracts attribute values data from a work package.
      #
      # The values are to be displayed in the table.
      #
      # Override if:
      # - multiple attributes are extracted from a work package for a column
      #   type (for instance `Hierarchy` column type extracts both `subject` and
      #   `parent` attributes)
      # - or if the value is not read from a work package attribute, but from
      #   one of its relations (for instance, `Status` column type reads
      #   `work_package.status.name` to have a string value, because
      #   `work_package.status` alone is not a string).
      def attributes_for_work_package(attribute, work_package)
        { attribute => work_package.read_attribute(attribute) }
      end

      # Extracts attribute values data from the raw value read from a cell.
      #
      # Override if:
      # - multiple attributes are extracted from a single cell raw value for a
      #   column type (for instance `Hierarchy` column type extracts both
      #   `subject` and `parent` attributes)
      def attributes_for_raw_value(attribute, raw_value, _data, _work_packages_data)
        { attribute => parse(raw_value) }
      end

      # Extracts metadata from the raw value read from a cell.
      #
      # The metadata is useful to store additional information about the row.
      #
      # Override when needing to store additional metadata. For instance the
      # `Subject` column type stores the work package identifier as metadata.
      def metadata_for_raw_value(_raw_value)
        {}
      end
    end
  end
end
