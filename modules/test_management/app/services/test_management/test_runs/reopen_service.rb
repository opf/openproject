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
    # Reopens a completed/cancelled run (back to in_progress). Frozen statuses are
    # released; the history events written on finishing are kept.
    class ReopenService < TransitionService
      private

      def allowed_from
        TestRun::FINISHED_STATES
      end

      def perform(**)
        run.update!(state: "in_progress", finished_at: nil, finished_by: nil, completion_source: nil)
        run.run_cases.update_all(final_status: nil, updated_at: Time.current)
        SyncCasesService.new(run).call
      end
    end
  end
end
