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

class WorkPackages::MovesController < ApplicationController
  include WorkPackages::BulkErrorMessage
  include WorkPackages::IdListNormalization
  include OpTurbo::ComponentStream
  include WorkPackages::Shared::MovePlanning

  default_search_scope :work_packages
  before_action :find_work_packages, :check_project_uniqueness
  before_action :authorize_move_or_copy
  authorization_checked! :new, :create, :refresh_form, :move_dialog, :confirm_move

  def new
    prepare_for_work_package_move

    @descendant_counts = descendant_counts
    @move_form_component = move_form_component
  end

  def create
    prepare_for_work_package_move

    perform_operation
  end

  def refresh_form
    prepare_for_work_package_move

    update_via_turbo_stream(component: move_form_component)

    respond_with_turbo_streams
  end

  def move_dialog
    if has_visible_descendants?
      respond_with_dialog move_dialog_component
    else
      # A plain browser navigation, not a Turbo visit: the move form's Angular
      # project autocompleter does not expect to be reached via a soft nav and
      # ends up rendering twice (two elements sharing id="new_project_id").
      render turbo_stream: turbo_stream.redirect_to(move_form_redirect_path, turbo: false)
    end
  end

  def confirm_move
    redirect_to move_form_redirect_path(move_descendants: params[:move_descendants])
  end

  private

  def move_roots = @work_packages.to_a

  def move_user = current_user

  def move_form_redirect_path(**)
    new_move_work_packages_path(ids: @work_packages.map(&:id), back_url: params[:back_url], **)
  end

  # Only descendants the move would actually cascade onto -- same rule, same bulk
  # query WorkPackages::Shared::MovePlanning already uses for the dialog -- count
  # here, or the preview would overstate how many work packages are affected.
  # Copying is unaffected: it already has its own per-descendant permission check,
  # so it always counts the full subtree.
  def descendant_counts
    if @copy
      @work_packages.to_h { |wp| [wp.id, wp.descendants.size] }
    elsif @move_descendants
      movable_descendant_counts_by_root
    else
      Hash.new(0)
    end
  end

  def move_dialog_component
    if @work_packages.one?
      WorkPackages::MoveDialogComponent.new(work_package: @work_packages.first, back_url: params[:back_url])
    else
      WorkPackages::BulkMoveDialogComponent.new(work_packages: @work_packages, back_url: params[:back_url])
    end
  end

  def authorize_move_or_copy
    permission = params.has_key?(:copy) ? :copy_work_packages : :move_work_packages
    do_authorize(permission)
  end

  def perform_operation
    if within_frontend_threshold?
      perform_in_frontend
    else
      perform_in_background
    end
  end

  def within_frontend_threshold?
    WorkPackageHierarchy.where(ancestor_id: @work_packages).count <= Setting.work_packages_bulk_request_limit
  end

  # rubocop:disable Metrics/AbcSize
  def perform_in_frontend
    call = job_class
             .perform_now(**job_args)

    if call.success? && @work_packages.any?
      flash[:notice] = call.message
      redirect_to call.result
    else
      flash[:error] = bulk_error_message(@work_packages, call.dependent_results.first)
      redirect_back_or_default(project_work_packages_path(@project))
    end
  end

  # rubocop:enable Metrics/AbcSize

  def perform_in_background
    job = job_class.perform_later(**job_args)
    redirect_to job_status_path(job.job_id)
  end

  def job_args
    {
      user: current_user,
      work_package_ids: @work_packages.pluck(:id),
      project: @project,
      target_project: @target_project,
      params: attributes_for_create,
      follow: params[:follow]
    }
  end

  def job_class
    if @copy
      WorkPackages::BulkCopyJob
    else
      WorkPackages::BulkMoveJob
    end
  end

  # Check if project is unique before bulk operations
  def check_project_uniqueness
    unless @project
      # TODO: let users bulk move/copy work packages from different projects
      render_error message: :"work_packages.move.unsupported_for_multiple_projects", status: 400
      false
    end
  end

  def move_form_component
    WorkPackages::Moves::FormComponent.new(
      work_packages: @work_packages,
      project: @project,
      target_project: @target_project,
      notes: @notes,
      copy: @copy,
      selected_values: permitted_params.move_work_package_form_values,
      current_user:
    )
  end

  def prepare_for_work_package_move
    @copy = params.has_key? :copy
    if params[:new_project_id]
      @target_project = allowed_target_projects.find_by(id: params[:new_project_id])
    end
    @target_project ||= @project
    @notes = params[:notes] || ""
    # Absent means cascade, consistent with WorkPackages::UpdateService's default.
    @move_descendants = ActiveModel::Type::Boolean.new.cast(params.fetch(:move_descendants, true))
  end

  def allowed_target_projects
    if @copy
      WorkPackage.allowed_target_projects_on_copy(current_user)
    else
      WorkPackage.allowed_target_projects_on_move(current_user)
    end
  end

  def attributes_for_create
    attributes = permitted_params.move_work_package
    id_lists = extract_normalized_id_lists(attributes)

    attributes
      .compact_blank
      # 'none' is used in the frontend as a value to unset the property, e.g. the assignee.
      .transform_values { |v| v == "none" ? nil : v }
      .to_h
      .merge(id_lists)
  end
end
