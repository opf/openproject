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
    # Column to add successors to work packages like "wp1, wp2 with lag 2, wp3".
    #
    # Supported texts:
    #   - :wp
    #   - :wp with lag :int
    #   - precedes :wp
    #   - precedes :wp with lag :int
    # They can be combined by separated them with commas: "precedes wp1, wp2 with lag 2, wp3".
    #
    # Example:
    #
    #   | subject      | successors                   |
    #   | predecessor2 | main, predecessor with lag 2 |
    #   | predecessor  | precedes main                |
    #   | main         |                              |
    class SuccessorRelations < Generic
      def attributes_for_work_package(_attribute, _work_package)
        {}
      end

      def extract_data(_attribute, raw_header, work_package_data, _work_packages_data)
        successors = work_package_data.dig(:row, raw_header)
        successors = successors.split(",").map(&:strip).compact_blank
        parse_successors(successors)
      end

      def parse_successors(successors)
        relations = successors.to_h do |successor|
          relation = parse_successor(successor)
          [relation[:with], relation]
        end
        { relations: }.compact_blank
      end

      def parse_successor(successor)
        case successor
        when /^(?:precedes)?\s*(.+?)(?: with lag (\d+))?\s*$/
          {
            raw: successor,
            type: :precedes,
            with: $1,
            lag: $2.to_i
          }
        else
          spell_checker = DidYouMean::SpellChecker.new(
            dictionary: [
              ":wp",
              ":wp with lag :int",
              "precedes :wp",
              "precedes :wp with lag :int"
            ]
          )
          suggestions = spell_checker.correct(successor).map(&:inspect).join(" ")
          did_you_mean = " Did you mean #{suggestions} instead?" if suggestions.present?
          raise "unable to parse successor #{successor.inspect}.#{did_you_mean}"
        end
      end
    end
  end
end
