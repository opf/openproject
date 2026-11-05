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
    # Creates iterations. No permission checks and no locking – callers (StartService,
    # Automation::IngestService) hold the run lock and have authorized the user.
    class Starter
      def initialize(run:, user:)
        @run = run
        @user = user
      end

      # Runs created before iterations existed (or never iterated) get iteration 1 on demand;
      # their existing results and imports are assigned to it. Returns the current iteration.
      def ensure_initial!(attributes = {})
        current = run.current_iteration
        return current if current

        iteration = create_iteration!(1, attributes)
        TestResult.where(run_case_id: run.run_cases.select(:id), iteration_id: nil).update_all(iteration_id: iteration.id)
        AutomationImport.where(test_run_id: run.id, iteration_id: nil).update_all(iteration_id: iteration.id)
        iteration
      end

      # Starts the next iteration and resets every run case to "untested" (results of earlier
      # iterations are kept). A run without any iteration and without results simply gets
      # iteration 1 with the given attributes, nothing to reset.
      def start!(attributes = {}) # rubocop:disable Metrics/AbcSize
        if run.current_iteration.nil? && !results_exist?
          return create_iteration!(1, attributes)
        end

        previous = ensure_initial!
        iteration = create_iteration!(previous.number + 1, attributes)
        run.run_cases.where.not(status: "untested").update_all(status: "untested", updated_at: Time.current)
        run.update!(state: "new") if run.state == "in_progress"
        iteration
      end

      private

      attr_reader :run, :user

      def results_exist?
        TestResult.exists?(run_case_id: run.run_cases.select(:id)) ||
          run.run_cases.where.not(status: "untested").exists?
      end

      def create_iteration!(number, attributes) # rubocop:disable Metrics/AbcSize
        attributes = attributes.to_h.symbolize_keys.slice(:name, :source, :external_ref, :ci_metadata, :connection)
        attributes[:name] = attributes[:name].to_s.strip.first(255).presence
        attributes[:source] ||= "manual"
        attributes[:ci_metadata] ||= {}
        run.iterations.create!(number:, created_by: user, **attributes).tap { run.iterations.reset }
      end
    end
  end
end
