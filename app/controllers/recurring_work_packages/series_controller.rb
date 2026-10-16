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

module RecurringWorkPackages
  class SeriesController < ApplicationController
    include OpTurbo::ComponentStream

    SIDEBAR_ENTRY = "recurring_work_packages"

    before_action :find_work_package, only: %i[new preview create]
    before_action :find_project_by_project_id, only: %i[index show create_next end_series]
    before_action :find_series, only: %i[show create_next end_series]
    before_action :authorize
    before_action :highlight_sidebar_entry, only: %i[index show]

    menu_item :work_packages

    def index
      @series = Series
        .where(project: @project)
        .includes(occurrences: { work_package: %i[status assigned_to] })
        .order(:id)
    end

    def show
      @occurrences = @series.occurrences.includes(work_package: %i[status type assigned_to])
      @upcoming = @series.upcoming_dates
    end

    def new
      respond_with_dialog DialogComponent.new(work_package: @work_package)
    end

    def preview
      series = Series.new(series_params.compact_blank)
      update_via_turbo_stream(component: PreviewComponent.new(series:))
      respond_with_turbo_streams
    end

    def create
      result = CreateService.new(user: current_user, work_package: @work_package).call(series_params)

      if result.success?
        flash[:notice] = t("recurring_work_packages.dialog.created", schedule: result.result.schedule_in_words)
        reload_page_via_turbo_stream
      else
        update_via_turbo_stream(component: FormComponent.new(work_package: @work_package, series: result.result))
      end

      respond_with_turbo_streams(status: result.success? ? :ok : :unprocessable_entity)
    end

    def create_next
      result = CreateNextService.new(user: current_user, series: @series).call

      if result.success?
        flash[:notice] = t("recurring_work_packages.series.next_created", id: result.result.display_id)
      else
        flash[:error] = result.errors.full_messages.join(", ")
      end

      redirect_to project_recurring_work_package_path(@project, @series), status: :see_other
    end

    def end_series
      @series.update!(end_after: :specific_date, end_date: @series.latest_occurrence.scheduled_date)
      @series.work_packages.touch_all

      redirect_to project_recurring_work_package_path(@project, @series),
                  notice: t("recurring_work_packages.series.ended"),
                  status: :see_other
    end

    private

    def find_work_package
      @work_package = WorkPackage.visible.find(params[:id] || params[:work_package_id])
      @project = @work_package.project
    end

    def find_series
      @series = Series.where(project: @project).find(params.expect(:id))
    end

    def highlight_sidebar_entry
      params[:name] = SIDEBAR_ENTRY
    end

    def series_params
      params.expect(series: %i[frequency interval start_date end_after end_date iterations])
    end
  end
end
