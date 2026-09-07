# frozen_string_literal: true

class WorkPackages::BulkImportsController < ApplicationController
  before_action :find_project_by_project_id

  authorize_with_permission :add_work_packages

  def new
  end

  def create
    call = WorkPackages::BulkImportService.new(user: current_user, project: @project, file: params[:file]).call

    if call.success?
      flash[:notice] = I18n.t("work_packages.bulk_import.success", count: call.result.size)
      redirect_to project_work_packages_path(@project), status: :see_other
    else
      @errors = call.errors.full_messages
      render :new, status: :unprocessable_entity
    end
  rescue ArgumentError => e
    @errors = [e.message]
    render :new, status: :unprocessable_entity
  end

  def sample
    send_data WorkPackages::BulkImportService.sample_csv,
              type: "text/csv",
              filename: "work-packages-sample.csv"
  end
end