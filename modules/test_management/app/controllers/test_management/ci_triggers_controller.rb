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
  class CiTriggersController < ApplicationController
    menu_item :test_management

    before_action :find_project_by_project_id
    before_action :authorize

    include TestManagement::CiFeature

    before_action :load_scope

    def new
      @trigger = CiTriggers::Request.new(project: @project, run: @scope_run, suite: @suite, test_case: @test_case,
                                         mode: @scope_run&.active? ? "new_iteration" : "new_run",
                                         connection: trigger_connections.find(&:trigger_ready?))
      load_form_data
    end

    def create # rubocop:disable Metrics/AbcSize
      call = CiTriggers::TriggerService.new(user: current_user).call(trigger_params)
      if call.success?
        outcome = call.result
        if outcome.triggered?
          flash[:notice] = I18n.t("test_management.ci_triggers.triggered", run: outcome.run.name,
                                                                           number: outcome.iteration.number)
        else
          flash[:error] = I18n.t("test_management.ci_triggers.failed", error: outcome.error)
        end
        redirect_to project_test_management_test_run_path(@project, outcome.run), status: :see_other
      else
        @trigger = call.result
        flash.now[:error] = call.errors.full_messages.join(", ")
        load_form_data
        render :new, status: :unprocessable_entity
      end
    end

    private

    def load_scope # rubocop:disable Metrics/AbcSize
      source = params[:ci_trigger].presence || params
      @scope_run = @project.tm_test_runs.find(source[:run_id]) if source[:run_id].present?
      @suite = @project.tm_suites.find(source[:suite_id]) if source[:suite_id].present?
      @test_case = @project.tm_test_cases.find(source[:test_case_id]) if source[:test_case_id].present?
    end

    def trigger_params # rubocop:disable Metrics/AbcSize
      values = params.fetch(:ci_trigger, {}).permit(:connection_id, :mode, :target_run_id, :ref, :name)
      mode = values[:mode].presence || "new_run"
      target = if mode == "new_iteration"
                 values[:target_run_id].present? ? @project.tm_test_runs.find_by(id: values[:target_run_id]) : @scope_run
               else
                 @scope_run
               end
      {
        project: @project,
        connection: CiConnection.where(project_id: @project.id).find_by(id: values[:connection_id]),
        mode:, run: target, suite: @suite, test_case: @test_case,
        ref: values[:ref], name: values[:name]
      }
    end

    def trigger_connections
      @trigger_connections ||= CiConnection.where(project_id: @project.id).active.ordered.to_a
    end

    def load_form_data
      @connections = trigger_connections
      @target_runs = @project.tm_test_runs.active.newest_first.limit(200).to_a
      @automated_count = @trigger.automated_cases.count
      @case_count = @trigger.cases.count
    end
  end
end
