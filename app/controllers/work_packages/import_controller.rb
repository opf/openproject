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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackages::ImportController < ApplicationController
  RUNNING = %w[in_queue in_process].freeze

  menu_item :work_packages
  before_action :find_project_by_project_id, :authorize
  before_action :load_status, only: %i[show status problems]

  helper_method :import_running?, :import_checked?, :import_settled?

  def show; end

  def status
    respond_to do |format|
      format.turbo_stream { render turbo_stream: report_streams }
      format.html { redirect_to import_project_work_packages_path(@project, job: params[:job]) }
    end
  end

  def create
    refused = missing_file_error
    return refuse(refused) if refused

    result = schedule

    if result.success?
      redirect_to import_project_work_packages_path(@project, job: result.result)
    else
      refuse(result.message, expired: result.result == :expired)
    end
  end

  def problems
    return head(:not_found) if @status.blank?

    send_data ::WorkPackages::Import::CSV::ProblemReport.call(payload: @status.payload),
              filename: "#{File.basename(@status.payload['filename'].to_s, '.*')}-problems.csv",
              type: "text/csv; charset=utf-8"
  end

  def template
    send_data ::WorkPackages::Import::CSV::Template.call(project: @project),
              filename: ::WorkPackages::Import::CSV::Template::FILENAME,
              type: "text/csv; charset=utf-8"
  end

  private

  def import_outcome = @status&.payload&.dig("outcome")

  def import_running? = @status.present? && import_outcome.blank?

  def import_checked? = import_outcome == "checked"

  def import_settled? = %w[checked imported].include?(import_outcome) && @error.blank?

  def report_streams
    [turbo_stream.replace("import_report", partial: "work_packages/import/report"),
     turbo_stream.replace("import_form", partial: "work_packages/import/form")]
  end

  def load_status
    return if params[:job].blank?

    status = ::JobStatus::Status.find_by(job_id: params[:job], user_id: current_user.id)
    @status = status if status && status.payload["project_id"] == @project.id

    validate_run_state
  end

  def validate_run_state
    return unless @status && @status.payload["outcome"].blank? && RUNNING.exclude?(@status.status)

    @error = t("work_packages.import.run_failed")
    @status = nil
  end

  # A refused upload is a form error, not a run: re-render the page with the message on the file field
  def refuse(message, expired: false)
    load_status

    @error = expired ? expired_message(message) : message

    render :show, status: :unprocessable_entity
  end

  def expired_message(fallback)
    filename = @status&.payload&.dig("filename")

    filename.present? ? t("work_packages.import.csv.file.expired_named", filename:) : fallback
  end

  def missing_file_error
    if uploaded_file
      t("work_packages.import.csv.file.empty") if uploaded_file.size.to_i.zero?
    elsif params[:file].present? || params[:attachment_id].blank?
      t("work_packages.import.csv.file.missing")
    end
  end

  def uploaded_file
    file = params[:file]

    file if file.is_a?(ActionDispatch::Http::UploadedFile)
  end

  def schedule
    ::WorkPackages::Import::CSV::ScheduleService
      .new(user: current_user, project: @project)
      .call(file: uploaded_file, attachment_id: params[:attachment_id], dry_run: dry_run?)
  end

  def dry_run?
    ActiveModel::Type::Boolean.new.cast(params.fetch(:dry_run, true))
  end
end
