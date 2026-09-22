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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  module Import
    module CSV
      # Turns a CSV header row into a mapping of work package attribute to column index,
      # or into the problems that stop the file being read at all.
      class HeaderMap
        CANONICAL = {
          "subject" => :subject,
          "description" => :description,
          "type" => :type,
          "status" => :status,
          "priority" => :priority,
          "category" => :category,
          "assignee" => :assigned_to,
          "start date" => :start_date,
          "finish date" => :due_date,
          "work" => :estimated_hours,
          "% complete" => :done_ratio,
          "created on" => :created_at,
          "updated on" => :updated_at
        }.freeze

        ATTRIBUTES = CANONICAL.values.freeze

        Problem = Data.define(:column, :header, :message)

        def self.call(headers) = new.call(headers)

        # @param headers [Array<String>] the header row, in file order
        # @return [ServiceResult] success carries {attribute => column index},
        #   failure carries an array of Problem
        def call(headers)
          @mapping = {}
          @seen = {}
          @problems = []

          headers.each_with_index { |header, index| examine(header, index) }

          if @problems.empty?
            ServiceResult.success(result: @mapping)
          else
            ServiceResult.failure(result: @problems)
          end
        end

        def resolve(header) = lookup[normalize(header)]

        # Canonical last, so a locale take it over if named the same.
        def lookup = @lookup ||= localized_aliases.merge(CANONICAL)

        def normalize(header)
          header.to_s.strip.delete_prefix("'").gsub(/\s+/, " ").strip.downcase
        end

        private

        def examine(header, index)
          return @problems << unnamed(index, header) if header.blank?

          attribute = resolve(header)

          if attribute.nil?
            @problems << unknown(index, header)
          elsif @seen.key?(attribute)
            @problems << repeated(index, header, attribute, @seen[attribute])
          else
            @seen[attribute] = header.to_s.strip
            @mapping[attribute] = index
          end
        end

        def localized_aliases
          captions = ATTRIBUTES.index_with { |attribute| normalize(WorkPackage.human_attribute_name(attribute)) }
          shared = captions.values.tally.select { |_, count| count > 1 }.keys

          captions.reject { |_, caption| shared.include?(caption) }.invert
        end

        def unnamed(index, header)
          problem(index, header, I18n.t("work_packages.import.csv.header.unnamed"))
        end

        def unknown(index, header)
          suggestion = suggestion_for(header)
          message = if suggestion
                      I18n.t("work_packages.import.csv.header.unknown_with_suggestion", suggestion:)
                    else
                      I18n.t("work_packages.import.csv.header.unknown")
                    end

          problem(index, header, message)
        end

        def repeated(index, header, attribute, first)
          message = if normalize(header) == normalize(first)
                      I18n.t("work_packages.import.csv.header.duplicate")
                    else
                      I18n.t("work_packages.import.csv.header.ambiguous",
                             other: first,
                             attribute: WorkPackage.human_attribute_name(attribute))
                    end

          problem(index, header, message)
        end

        def problem(index, header, message)
          Problem.new(column: column_letter(index), header: header.to_s.strip, message:)
        end

        def suggestion_for(header)
          match = DidYouMean::SpellChecker.new(dictionary: lookup.keys).correct(normalize(header)).first

          display(match) if match
        end

        def display(normalized) = WorkPackage.human_attribute_name(lookup[normalized])

        def column_letter(index)
          letters = +""
          remaining = index

          loop do
            letters.prepend(("A".ord + (remaining % 26)).chr)
            remaining = (remaining / 26) - 1
            break if remaining.negative?
          end

          letters
        end
      end
    end
  end
end
