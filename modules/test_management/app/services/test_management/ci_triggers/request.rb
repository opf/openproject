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
  module CiTriggers
    class Request
      include ActiveModel::Model
      include ActiveModel::Attributes

      MODES = %w[new_run new_iteration].freeze
      GREP_MAX_LENGTH = 1000

      attr_accessor :project, :connection, :run, :suite, :test_case

      attribute :mode, :string, default: "new_run"
      attribute :ref, :string
      attribute :name, :string

      def self.model_name = ActiveModel::Name.new(self, nil, "CiTrigger")

      def new_iteration? = mode == "new_iteration"

      def effective_ref = ref.to_s.strip.presence || connection&.effective_trigger_ref

      def cases # rubocop:disable Metrics/AbcSize
        return TestCase.none if project.nil?

        scope = TestCase.where(project_id: project.id)
        if test_case
          scope.where(id: test_case.id)
        elsif suite
          scope.where(suite_id: Suite.subtree_ids(project, [suite.id]))
        elsif run
          scope.where(id: run.run_cases.select(:test_case_id))
        else
          TestCase.none
        end
      end

      def automated_cases
        cases.where.not(automation_reference: [nil, ""]).order(:id)
      end

      # Playwright-style --grep pattern. Empty when it would exceed GREP_MAX_LENGTH: the job then
      # runs everything and the upload is still filed into the pre-created iteration.
      def grep
        parts = automated_cases.pluck(:automation_reference).map do |reference|
          Regexp.escape(reference.split("#", 2).last.strip)
        end
        pattern = parts.uniq.join("|")
        pattern.length > GREP_MAX_LENGTH ? "" : pattern
      end

      def scope_label
        if test_case then "##{test_case.id} #{test_case.title}"
        elsif suite then suite.name
        elsif run then run.name
        end
      end
    end
  end
end
