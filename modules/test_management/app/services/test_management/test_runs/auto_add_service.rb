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
    class AutoAddService
      def initialize(test_case)
        @test_case = test_case
      end

      def call # rubocop:disable Metrics/AbcSize
        runs = TestRun.active
                      .where(project_id: test_case.project_id, selection_mode: "all")
                      .where.not(id: TestRunCase.where(test_case_id: test_case.id).select(:test_run_id))

        runs.select { |run| run.matches?(test_case) }.each do |run|
          run.run_cases.create!(test_case:, assigned_to_id: run.assigned_to_id, status: "untested")
        end
      end

      private

      attr_reader :test_case
    end
  end
end
