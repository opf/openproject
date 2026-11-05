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
  class SuitesController < ApplicationController
    menu_item :test_management

    before_action :find_project_by_project_id
    before_action :authorize

    def index
      redirect_to project_test_management_test_cases_path(@project)
    end

    def create # rubocop:disable Metrics/AbcSize
      call = TestManagement::Suites::CreateService
               .new(user: current_user)
               .call(suite_params.merge(project: @project))

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_test_management_test_cases_path(@project, suite_id: call.result.id)
      else
        flash[:error] = call.errors.full_messages.join(", ")
        redirect_to project_test_management_test_cases_path(@project, suite_id: suite_params[:parent_id].presence)
      end
    end

    def update # rubocop:disable Metrics/AbcSize
      suite = @project.tm_suites.find(params.expect(:id))
      call = TestManagement::Suites::UpdateService
               .new(user: current_user, model: suite)
               .call(suite_params)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end

      redirect_to project_test_management_test_cases_path(@project, suite_id: suite.id)
    end

    def destroy # rubocop:disable Metrics/AbcSize
      suite = @project.tm_suites.find(params.expect(:id))
      call = TestManagement::Suites::DeleteService
               .new(user: current_user, model: suite)
               .call

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end

      redirect_to project_test_management_test_cases_path(@project)
    end

    private

    def suite_params
      params.expect(suite: %i[name parent_id position])
    end
  end
end
