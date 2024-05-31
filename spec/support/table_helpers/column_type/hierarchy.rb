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
    # Adds the `:identifier` metadata to the row.
    #
    # The `:identifier` value is the key being used to identify a work package
    # by its variable name. It's also the variable name to be used when using
    # the work packages in the tests.
    class Hierarchy < Generic
      include WithIdentifierMetadata

      def attributes_for_work_package(_attribute, work_package)
        {
          parent: to_identifier(work_package.parent&.subject),
          subject: work_package.subject
        }
      end

      def attributes_for_raw_value(_attribute, raw_value, data, work_packages_data)
        {
          parent: find_parent(raw_value, data, work_packages_data),
          subject: parse(raw_value)
        }
      end

      def metadata_for_raw_value(raw_value)
        super.merge(hierarchy_indent: hierarchy_indent(raw_value))
      end

      private

      def hierarchy_indent(raw_value)
        raw_value[/\A */].size
      end

      def find_parent(raw_value, data, work_packages_data)
        hierarchy_indent = hierarchy_indent(raw_value)
        return if hierarchy_indent == 0

        work_packages_data
            .slice(0, data[:index])
            .reverse
            .find { _1[:hierarchy_indent] < hierarchy_indent }
            .then { _1&.fetch(:identifier) }
      end
    end
  end
end
