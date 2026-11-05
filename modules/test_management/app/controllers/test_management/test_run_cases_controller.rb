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
  class TestRunCasesController < ApplicationController
    helper TestManagement::TestCasesHelper
    helper TestManagement::TestRunsHelper

    HISTORY_LIMIT = 50

    menu_item :test_management

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_run_case

    def show
      @test_case = @run_case.test_case
      @case_steps = @test_case.steps.to_a
      @results = @run_case.results.includes(:user, :iteration).order(id: :desc).limit(HISTORY_LIMIT).to_a
      @latest = @results.first
      @can_execute = @test_run.active? &&
                     (current_user.allowed_in_project?(:execute_test_runs, @project) ||
                      current_user.allowed_in_project?(:add_test_runs, @project))
    end

    def update
      call = TestManagement::RunCases::UpdateService
               .new(user: current_user, model: @run_case)
               .call(run_case_params)

      if call.success?
        flash[:notice] = I18n.t("test_management.runs.status_updated")
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end

      redirect_to return_path, status: :see_other
    end

    private

    def find_run_case
      @test_run = @project.tm_test_runs.find(params.expect(:test_run_id))
      @run_case = @test_run.run_cases.find(params.expect(:id))
    end

    def return_path
      if params[:return_to] == "run_case"
        project_test_management_test_run_run_case_path(@project, @test_run, @run_case)
      else
        project_test_management_test_run_path(@project, @test_run, anchor: "run-case-#{@run_case.id}")
      end
    end

    def run_case_params
      params.expect(run_case: %i[status assigned_to_id comment]).to_h
    end
  end
end
