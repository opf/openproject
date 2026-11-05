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
    class TriggerService
      Outcome = Struct.new(:run, :iteration, :status, :url, :external_id, :error, :grep, :ref, # rubocop:disable Lint/StructNewOverride
                           keyword_init: true) do
        def triggered? = status == "triggered"
      end

      def initialize(user:)
        @user = user
      end

      def call(params) # rubocop:disable Metrics/AbcSize
        request = Request.new(**params.to_h.symbolize_keys.slice(:project, :connection, :mode, :run, :suite,
                                                                 :test_case, :ref, :name).compact)
        contract = TriggerContract.new(request, user)
        return ServiceResult.failure(result: request, errors: contract.errors) unless contract.valid?

        run, iteration = prepare(request)
        inputs = {
          "op_run_id" => run.id, "op_iteration_id" => iteration.id,
          "op_project" => request.project.identifier, "op_grep" => request.grep
        }
        result = Dispatchers::Base.for(request.connection).call(ref: request.effective_ref, inputs:)
        record(run, iteration, request, result)

        ServiceResult.success(result: Outcome.new(run:, iteration:, status: result.status, url: result.url,
                                                  external_id: result.external_id, error: result.error,
                                                  grep: inputs["op_grep"], ref: request.effective_ref))
      end

      private

      attr_reader :user

      def prepare(request) # rubocop:disable Metrics/AbcSize
        TestRun.transaction do
          run = request.new_iteration? ? request.run : create_run(request)
          run.with_lock do
            run.add_cases!(request.cases.order(:id)) if request.new_iteration? && run.selection_mode == "specific"
            iteration = TestRunIterations::Starter.new(run:, user:).start!(
              name: request.name.presence || I18n.t("test_management.ci_triggers.iteration_name",
                                                    connection: request.connection.name),
              source: "automation", connection: request.connection,
              ci_metadata: { "trigger" => { "status" => "pending", "ref" => request.effective_ref } }
            )
            [run, iteration]
          end
        end
      end

      def create_run(request)
        run = TestRun.new(
          project: request.project,
          name: (request.name.presence || I18n.t("test_management.ci_triggers.run_name",
                                                 target: request.scope_label, connection: request.connection.name)).first(255),
          source: "automation", selection_mode: "specific", state: "new",
          author: user, connection: request.connection
        )
        run.save!
        run.add_cases!(request.cases.order(:id))
        run
      end

      def record(run, iteration, request, result) # rubocop:disable Metrics/AbcSize
        now = Time.current
        run.update_columns(ci_trigger_status: result.status, ci_trigger_url: result.url,
                           ci_trigger_error: result.error, ci_triggered_at: now, updated_at: now)
        trigger = { "status" => result.status, "url" => result.url, "externalId" => result.external_id,
                    "error" => result.error, "ref" => request.effective_ref, "connection" => request.connection.name,
                    "triggeredBy" => user.id, "triggeredAt" => now.utc.iso8601 }.compact
        metadata = iteration.ci_info.merge("trigger" => trigger)
        metadata["runUrl"] ||= result.url if result.triggered? && result.url
        metadata["provider"] ||= request.connection.provider
        iteration.update_columns(ci_metadata: metadata, updated_at: now)
      end
    end
  end
end
