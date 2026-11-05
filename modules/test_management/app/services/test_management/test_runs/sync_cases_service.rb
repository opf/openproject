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
    class SyncCasesService
      def initialize(run)
        @run = run
      end

      def call
        return run unless run.active?

        if run.selection_mode == "specific"
          sync_specific
        else
          run.add_cases!
        end
        run.selected_case_ids = nil
        run
      end

      private

      attr_reader :run

      def sync_specific
        ids = run.selected_case_ids
        return if ids.nil?

        run.run_cases.where.not(test_case_id: ids).destroy_all
        run.add_cases!(run.project.tm_test_cases.where(id: ids).order(:id))
      end
    end
  end
end
