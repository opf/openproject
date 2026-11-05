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
  module TestRuns
    class SetAttributesService < ::BaseServices::SetAttributes
      private

      def set_attributes(params)
        params = params.to_h.with_indifferent_access
        test_case_ids = params.key?(:test_case_ids) ? params.delete(:test_case_ids) : nil
        selection_suite_ids = params.delete(:selection_suite_ids)
        filter = params.key?(:filter_options) ? params.delete(:filter_options) : nil

        super

        model.filter_options = normalize_filter(filter) unless filter.nil?
        assign_selection(test_case_ids, selection_suite_ids)
      end

      def set_default_attributes(_params)
        model.author ||= user
        model.state ||= "new"
        model.selection_mode ||= "specific"
      end

      def normalize_filter(raw)
        raw = raw.to_h.with_indifferent_access
        automation = raw[:automation].to_s
        {
          "suite_ids" => ids_from(raw[:suite_ids]),
          "automation" => TestRun::AUTOMATION_FILTERS.include?(automation) ? automation : "any"
        }
      end

      def assign_selection(test_case_ids, suite_ids) # rubocop:disable Metrics/AbcSize
        return if test_case_ids.nil? && suite_ids.nil?

        ids = ids_from(test_case_ids)
        folder_ids = ids_from(suite_ids)
        if folder_ids.any? && model.project
          subtree = TestManagement::Suite.subtree_ids(model.project, folder_ids)
          ids |= model.project.tm_test_cases.where(suite_id: subtree).pluck(:id)
        end
        model.selected_case_ids = ids.uniq
      end

      def ids_from(raw)
        Array(raw)
          .flat_map { |value| value.to_s.split(/[\s,]+/) }
          .map { |value| value.delete_prefix("#") }
          .grep(/\A\d+\z/)
          .map(&:to_i)
          .uniq
      end
    end
  end
end
