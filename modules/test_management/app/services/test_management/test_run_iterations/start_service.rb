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
  module TestRunIterations
    # "Start new iteration" on the run page (or POST …/runs/:id/iterations):
    # re-execute the same set of cases. Requires :add_test_runs and an active run.
    class StartService
      def initialize(user:, run:)
        @user = user
        @run = run
      end

      def call(params = {}) # rubocop:disable Metrics/AbcSize
        params = params.to_h.with_indifferent_access
        return failure(:error_unauthorized) unless user.allowed_in_project?(:add_test_runs, run.project)
        return failure(:tm_run_finished) if run.finished?

        name = params[:name].to_s.strip

        iteration = nil
        run.with_lock do
          iteration = Starter.new(run:, user:).start!(name:, source: "manual")
        end
        ServiceResult.success(result: iteration)
      end

      private

      attr_reader :user, :run

      def failure(error)
        errors = ActiveModel::Errors.new(run)
        errors.add(:base, error)
        ServiceResult.failure(result: run, errors:)
      end
    end
  end
end
