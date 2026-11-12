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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module TableHelpers
  module ColumnType
    # Column to add relates/related to relations to work packages.
    #
    # Supported texts:
    #   - :wp
    #
    # They can be combined by separated them with commas: "wp1, wp2".
    #
    # Example:
    #
    #   | subject   | related to |
    #   | main      |            |
    #   | other one | main       |
    class RelatedToRelations < Generic
      def attributes_for_work_package(_attribute, _work_package)
        {}
      end

      def extract_data(_attribute, raw_header, work_package_data, _work_packages_data)
        relations =
          work_package_data.dig(:row, raw_header)
                           .split(",")
                           .map(&:strip)
                           .compact_blank
                           .to_h do |name|
                             relation = make_related_to_relation(name)
                             [relation[:with], relation]
                           end
        { relations: }.compact_blank
      end

      def make_related_to_relation(name)
        {
          raw: name,
          type: :relates,
          with: name
        }
      end
    end
  end
end
