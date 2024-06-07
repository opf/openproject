# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2024 the OpenProject GmbH
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
# ++

class WorkPackages::ProgressController < ApplicationController
  ERROR_PRONE_ATTRIBUTES = %i[status_id
                              estimated_hours
                              remaining_hours
                              done_ratio].freeze

  layout false
  before_action :set_work_package
  before_action :extract_persisted_progress_attributes, only: %i[edit create update]

  helper_method :modal_class

  def new
    build_up_brand_new_work_package

    render modal_class.new(@work_package,
                           focused_field: params[:field],
                           touched_field_map:)
  end

  def edit
    build_up_work_package

    render modal_class.new(@work_package,
                           focused_field: params[:field],
                           format_durations: (params[:format_durations] || "true").to_bool,
                           touched_field_map:)
  end

  def create
    service_call = build_up_brand_new_work_package

    if service_call.errors
                   .map(&:attribute)
                   .intersect?(ERROR_PRONE_ATTRIBUTES)
      respond_to do |format|
        format.turbo_stream do
          # Bundle 422 status code into stream response so
          # Angular has context as to the success or failure of
          # the request in order to fetch the new set of Work Package
          # attributes in the ancestry solely on success.
          render :update, status: :unprocessable_entity
        end
      end
    else
      render json: { estimatedTime: formatted_duration(@work_package.estimated_hours),
                     remainingTime: formatted_duration(@work_package.remaining_hours) }
    end
  end

  def update
    service_call = WorkPackages::UpdateService
                     .new(user: current_user,
                          model: @work_package)
                     .call(work_package_params)

    if service_call.success?
      respond_to do |format|
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.turbo_stream do
          # Bundle 422 status code into stream response so
          # Angular has context as to the success or failure of
          # the request in order to fetch the new set of Work Package
          # attributes in the ancestry solely on success.
          render :update, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def modal_class
    if WorkPackage.use_status_for_done_ratio?
      WorkPackages::Progress::StatusBased::ModalBodyComponent
    else
      WorkPackages::Progress::WorkBased::ModalBodyComponent
    end
  end

  def set_work_package
    @work_package = WorkPackage.visible.find(params[:work_package_id])
  rescue ActiveRecord::RecordNotFound
    @work_package = WorkPackage.new
  end

  def touched_field_map
    params.require(:work_package).permit("estimated_hours_touched",
                                         "remaining_hours_touched",
                                         "status_id_touched").to_h
  end

  def extract_persisted_progress_attributes
    @persisted_progress_attributes = @work_package
                                       .attributes
                                       .slice("estimated_hours", "remaining_hours", "status_id")
  end

  def work_package_params
    params.require(:work_package)
          .permit(allowed_params)
  end

  def allowed_params
    if WorkPackage.use_status_for_done_ratio?
      %i[estimated_hours status_id]
    else
      %i[estimated_hours remaining_hours]
    end
  end

  def filtered_work_package_params
    {}.tap do |filtered_params|
      filtered_params[:estimated_hours] = work_package_params["estimated_hours"] if estimated_hours_touched?
      filtered_params[:remaining_hours] = work_package_params["remaining_hours"] if remaining_hours_touched?
      filtered_params[:status_id] = work_package_params["status_id"] if status_id_touched?
    end
  end

  def estimated_hours_touched?
    params.require(:work_package)[:estimated_hours_touched] == "true"
  end

  def remaining_hours_touched?
    params.require(:work_package)[:remaining_hours_touched] == "true"
  end

  def status_id_touched?
    params.require(:work_package)[:status_id_touched] == "true"
  end

  def build_up_work_package
    WorkPackages::SetAttributesService
      .new(user: current_user,
           model: @work_package,
           contract_class: WorkPackages::CreateContract)
      .call(filtered_work_package_params)
  end

  def build_up_brand_new_work_package
    WorkPackages::SetAttributesService
      .new(user: current_user,
           model: @work_package,
           contract_class: WorkPackages::CreateContract)
      .call(work_package_params)
  end

  def formatted_duration(hours)
    API::V3::Utilities::DateTimeFormatter.format_duration_from_hours(hours, allow_nil: true)
  end
end
