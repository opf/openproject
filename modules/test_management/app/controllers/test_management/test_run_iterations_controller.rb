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
  class TestRunIterationsController < ApplicationController
    menu_item :test_management

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_test_run

    def create # rubocop:disable Metrics/AbcSize
      call = TestManagement::TestRunIterations::StartService.new(user: current_user, run: @test_run)
                                                           .call(name: params.dig(:iteration, :name))
      if call.success?
        flash[:notice] = I18n.t("test_management.runs.iterations.started_notice", number: call.result.number)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
      redirect_to project_test_management_test_run_path(@project, @test_run), status: :see_other
    end

    private

    def find_test_run
      @test_run = @project.tm_test_runs.find(params.expect(:test_run_id))
    end
  end
end
