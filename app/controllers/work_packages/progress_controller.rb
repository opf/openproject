# frozen_string_literal: true

# -- copyright
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
# ++

class WorkPackages::ProgressController < ApplicationController
  ERROR_PRONE_ATTRIBUTES = %i[status_id
                              estimated_hours
                              remaining_hours
                              done_ratio].freeze

  layout false
  authorization_checked! :new, :edit, :create, :update

  helper_method :modal_class

  def new
    make_fake_initial_work_package
    set_progress_attributes_to_work_package

    render modal_class.new(@work_package,
                           focused_field: params[:field],
                           touched_field_map:)
  end

  def edit
    find_work_package
    set_progress_attributes_to_work_package

    render modal_class.new(@work_package,
                           focused_field: params[:field],
                           touched_field_map:)
  end

  # rubocop:disable Metrics/AbcSize
  def create
    make_fake_initial_work_package
    service_call = set_progress_attributes_to_work_package

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
    # following 3 lines to be removed in 15.0 with :percent_complete_edition feature flag removal
    elsif !OpenProject::FeatureDecisions.percent_complete_edition_active?
      render json: { estimatedTime: formatted_duration(@work_package.estimated_hours),
                     remainingTime: formatted_duration(@work_package.remaining_hours) }
    else
      render json: { estimatedTime: formatted_duration(@work_package.estimated_hours),
                     remainingTime: formatted_duration(@work_package.remaining_hours),
                     percentageDone: @work_package.done_ratio }
    end
  end
  # rubocop:enable Metrics/AbcSize

  def update
    find_work_package
    service_call = WorkPackages::UpdateService
                     .new(user: current_user,
                          model: @work_package)
                     .call(work_package_progress_params)

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

  def find_work_package
    @work_package = WorkPackage.visible.find(params[:work_package_id])
  end

  def make_fake_initial_work_package
    initial_params = params["work_package"]["initial"]
      .slice(*%w[estimated_hours remaining_hours done_ratio status_id])
      .permit!
    @work_package = WorkPackage.new(initial_params)
    @work_package.clear_changes_information
  end

  def touched_field_map
    params.require(:work_package)
          .slice("estimated_hours_touched",
                 "remaining_hours_touched",
                 "done_ratio_touched",
                 "status_id_touched")
          .transform_values { _1 == "true" }
          .permit!
  end

  def work_package_progress_params
    params.require(:work_package)
          .slice(*allowed_touched_params)
          .permit!
  end

  def allowed_touched_params
    allowed_params.filter { touched?(_1) }
  end

  def allowed_params
    if WorkPackage.use_status_for_done_ratio?
      %i[estimated_hours status_id]
    # two next lines to be removed in 15.0 with :percent_complete_edition feature flag removal
    elsif !OpenProject::FeatureDecisions.percent_complete_edition_active?
      %i[estimated_hours remaining_hours]
    else
      %i[estimated_hours remaining_hours done_ratio]
    end
  end

  def touched?(field)
    touched_field_map[:"#{field}_touched"]
  end

  def set_progress_attributes_to_work_package
    WorkPackages::SetAttributesService
      .new(user: current_user,
           model: @work_package,
           contract_class: WorkPackages::CreateContract)
      .call(work_package_progress_params)
  end

  def formatted_duration(hours)
    API::V3::Utilities::DateTimeFormatter.format_duration_from_hours(hours, allow_nil: true)
  end
end
