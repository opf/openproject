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
    # Column to add predecessors to work packages like "wp1, wp2 with lag 2, wp3".
    #
    # Supported texts:
    #   - :wp
    #   - :wp with lag :int
    #   - follows :wp
    #   - follows :wp with lag :int
    # They can be combined by separated them with commas: "follows wp1, wp2 with lag 2, wp3".
    #
    # Example:
    #
    #   | subject   | predecessors            |
    #   | main      |                         |
    #   | follower  | follows main with lag 2 |
    #   | follower2 | follows follower, main  |
    #
    # Adapted from (now deleted) original implementation
    # in `spec/support/schedule_helpers/chart_builder.rb`.
    class PredecessorRelations < Generic
      def attributes_for_work_package(_attribute, _work_package)
        {}
      end

      def extract_data(_attribute, raw_header, work_package_data, _work_packages_data)
        predecessors = work_package_data.dig(:row, raw_header)
        predecessors = predecessors.split(",").map(&:strip).compact_blank
        parse_predecessors(predecessors)
      end

      def parse_predecessors(predecessors)
        relations = predecessors.to_h do |predecessor|
          relation = parse_predecessor(predecessor)
          [relation[:with], relation]
        end
        { relations: }.compact_blank
      end

      def parse_predecessor(predecessor)
        case predecessor
        when /^(?:follows)?\s*(.+?)(?: with lag (\d+))?\s*$/
          {
            raw: predecessor,
            type: :follows,
            with: $1,
            lag: $2.to_i
          }
        else
          spell_checker = DidYouMean::SpellChecker.new(
            dictionary: [
              ":wp",
              ":wp with lag :int",
              "follows :wp",
              "follows :wp with lag :int"
            ]
          )
          suggestions = spell_checker.correct(predecessor).map(&:inspect).join(" ")
          did_you_mean = " Did you mean #{suggestions} instead?" if suggestions.present?
          raise "unable to parse predecessor #{predecessor.inspect}.#{did_you_mean}"
        end
      end
    end
  end
end
