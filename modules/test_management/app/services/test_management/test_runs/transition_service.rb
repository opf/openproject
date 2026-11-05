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
    class TransitionService
      def initialize(user:, model:)
        @user = user
        @run = model
      end

      def call(**) # rubocop:disable Metrics/AbcSize
        return failure(:error_unauthorized) unless permitted?
        return failure(:tm_invalid_transition) unless allowed_from.include?(run.state)

        TestRun.transaction do
          perform(**)
        end
        ServiceResult.success(result: run)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError => e
        run.errors.add(:base, e.message)
        ServiceResult.failure(result: run, errors: run.errors)
      end

      private

      attr_reader :user, :run

      def permitted?
        user.allowed_in_project?(:add_test_runs, run.project)
      end

      def allowed_from
        raise TestManagement::AbstractMethodError
      end

      def perform(**)
        raise TestManagement::AbstractMethodError
      end

      def failure(error)
        run.errors.add(:base, error)
        ServiceResult.failure(result: run, errors: run.errors)
      end
    end
  end
end
