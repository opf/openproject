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
    class RunResolver
      def initialize(user:, project:, options:, warnings: [], plan: nil)
        @user = user
        @project = project
        @options = options
        @warnings = warnings
        @plan = plan || ConnectionResolver::Plan.new(mode: options.mode || "new_run", target_run: options.target_run)
      end

      def call # rubocop:disable Metrics/AbcSize
        return [existing(run_of_iteration), false] if options.iteration_id
        return [existing(project.tm_test_runs.find_by(id: options.run_id)), false] if options.run_id
        return by_target_run if plan.new_iteration?
        return by_external_ref if options.external_ref

        [create_run, true]
      end

      private

      attr_reader :user, :project, :options, :warnings, :plan

      def run_of_iteration # rubocop:disable Metrics/AbcSize
        iteration = TestRunIteration.joins(:test_run).where(tm_test_runs: { project_id: project.id })
                                    .find_by(id: options.iteration_id)
        raise Error.new(:not_found, "The test run iteration does not exist in this project.") unless iteration
        if options.run_id && options.run_id.to_s != iteration.test_run_id.to_s
          raise Error.new(:unprocessable, "iterationId does not belong to runId.")
        end

        iteration.test_run
      end

      def by_target_run # rubocop:disable Metrics/AbcSize
        name = plan.target_run
        if name.blank?
          raise Error.new(:unprocessable, "mode new_iteration needs runId or targetRun (or a CI connection with a target run).")
        end

        project.with_lock do
          run = project.tm_test_runs.active.where("LOWER(tm_test_runs.name) = ?", name.downcase).newest_first.first
          next [run, false] if run

          warnings << { "code" => "target_run_created", "name" => name }
          [create_run(name:), true]
        end
      end

      def existing(run)
        raise Error.new(:not_found, "The test run does not exist in this project.") unless run
        if run.finished?
          raise Error.new(:conflict,
                          "Test run #{run.formatted_id} is #{run.state}; results can no longer be added.")
        end

        run
      end

      def by_external_ref
        run = project.tm_test_runs.find_by(external_ref: options.external_ref)
        return [existing(run), false] if run

        [create_run(external_ref: options.external_ref), true]
      rescue ActiveRecord::RecordNotUnique
        [existing(project.tm_test_runs.find_by(external_ref: options.external_ref)), false]
      end

      def create_run(external_ref: nil, name: nil)
        run = project.tm_test_runs.new(
          name: name || options.name || default_name,
          description: description,
          source: "automation",
          selection_mode: "specific",
          state: "in_progress",
          author: user,
          external_ref:,
          ci_metadata: options.ci,
          connection: plan.connection
        )
        run.save!
        run
      end

      def default_name
        options.ci_title || "Automation run #{Time.current.utc.iso8601}"
      end

      def description
        url = options.ci["runUrl"]
        url.present? && url.match?(%r{\Ahttps?://}i) ? "CI run: #{url}" : nil
      end
    end
  end
end
