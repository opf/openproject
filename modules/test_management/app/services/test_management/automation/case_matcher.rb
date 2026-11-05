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

module TestManagement
  module Automation
    class CaseMatcher
      Match = Struct.new(:cases, :matched_by, :reason, keyword_init: true)

      def initialize(project:, strategy: "auto")
        @project = project
        @strategy = strategy
      end

      def call(records)
        preload(records)
        records.map { |record| match(record) }
      end

      private

      attr_reader :project, :strategy

      def match(record)
        foreign = false
        steps.each do |step|
          ids_or_cases = send(:"by_#{step}", record)
          next if ids_or_cases.blank?

          cases, missing = resolve(ids_or_cases)
          foreign ||= missing
          return Match.new(cases:, matched_by: step) if cases.any?
        end
        Match.new(cases: [], reason: foreign ? "case_not_in_project" : "no_matching_case")
      end

      def steps
        strategy == "auto" ? %w[reference id] : [strategy]
      end

      def resolve(list)
        cases = list.filter_map { |item| item.is_a?(Integer) ? @cases_by_id[item] : item }.uniq
        [cases, cases.size < list.size]
      end

      def by_reference(record)
        [@cases_by_ref[record.reference]].compact
      end

      def by_id(record)
        ids = record.case_ids.filter_map { |value| value.to_s[/\d+/]&.to_i }
        ids = ids_in(record.tags.join(" ")) if ids.empty?
        ids = ids_in(record.title.to_s) if ids.empty?
        ids.uniq
      end

      def ids_in(text)
        text.scan(id_pattern).flatten.map(&:to_i)
      end

      def id_pattern
        @id_pattern ||= begin
          prefixes = [ProjectSetting.display_prefix_for(project), "TC"].compact_blank.map { |p| Regexp.escape(p) }.uniq
          /(?:^|[\s@\[(])(?:#{prefixes.join('|')})-?(\d+)\b/i
        end
      end

      def preload(records) # rubocop:disable Metrics/AbcSize
        refs = records.filter_map(&:reference).uniq
        @cases_by_ref = refs.any? ? project.tm_test_cases.where(automation_reference: refs).index_by(&:automation_reference) : {}
        ids = strategy.in?(%w[auto id]) ? records.flat_map { |r| by_id(r) }.uniq : []
        @cases_by_id = ids.any? ? project.tm_test_cases.where(id: ids).index_by(&:id) : {}
      end
    end
  end
end
