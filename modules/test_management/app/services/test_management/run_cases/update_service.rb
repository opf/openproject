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
  module RunCases
    class UpdateService
      def initialize(user:, model:)
        @user = user
        @run_case = model
      end

      def call(params) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
        params = params.to_h.with_indifferent_access
        run_case.errors.clear
        run = run_case.test_run

        return failure(:error_unauthorized) unless permitted?(run)
        return failure(:tm_run_finished) if run.finished?

        status = params[:status].presence
        return failure(:tm_invalid_status) if status && TestRunCase::STATUSES.exclude?(status)

        assignee_given = params.key?(:assigned_to_id)
        assignee_id = params[:assigned_to_id].presence&.to_i
        return failure(:tm_invalid_assignee) if assignee_given && assignee_id && !possible_assignee?(run, assignee_id)

        TestRunCase.transaction do
          run_case.assigned_to_id = assignee_id if assignee_given
          status_changed = status && status != run_case.status
          run_case.status = status if status
          run_case.save!

          if status_changed || params[:comment].present?
            run_case.results.create!(status: run_case.status, comment: params[:comment].presence, user:,
                                     iteration: run.current_iteration)
          end
          run.update!(state: "in_progress") if run.state == "new" && run_case.status != "untested"
        end

        ServiceResult.success(result: run_case)
      end

      private

      attr_reader :user, :run_case

      def permitted?(run)
        user.allowed_in_project?(:execute_test_runs, run.project) ||
          user.allowed_in_project?(:add_test_runs, run.project)
      end

      def possible_assignee?(run, id)
        TestManagement::Assignees.possible?(run.project, id)
      end

      def failure(error)
        run_case.errors.add(:base, error)
        ServiceResult.failure(result: run_case, errors: run_case.errors)
      end
    end
  end
end
