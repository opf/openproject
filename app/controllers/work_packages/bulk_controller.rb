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

class WorkPackages::BulkController < ApplicationController
  before_action :find_work_packages
  before_action :authorize

  include ProjectsHelper
  include CustomFieldsHelper
  include RelationsHelper
  include QueriesHelper

  include WorkPackages::BulkErrorMessage
  include WorkPackages::TargetVersionNormalization
  include OpTurbo::ComponentStream

  def delete_dialog
    component =
      if @work_packages.one?
        WorkPackages::DeleteDialogComponent.new(work_package: @work_packages.first, back_url: params[:back_url])
      else
        WorkPackages::BulkDeleteDialogComponent.new(work_packages: @work_packages, back_url: params[:back_url])
      end

    respond_with_dialog component
  end

  def confirm_delete
    return perform_deletion unless delete_descendants?

    close_dialog_via_turbo_stream(WorkPackages::DeleteDialogComponent::DIALOG_ID)
    dialog_via_turbo_stream(component: delete_descendants_dialog_component)

    respond_with_turbo_streams
  end

  def edit
    setup_edit
  end

  def update
    @call = ::WorkPackages::Bulk::UpdateService
      .new(user: current_user, work_packages: @work_packages)
      .call(attributes_for_update)

    if @call.success?
      flash[:notice] = t(:notice_successful_update)
      redirect_back_or_default({ controller: "/work_packages", action: :index, project_id: @project })
    else
      flash[:error] = bulk_error_message(@work_packages, @call)
      setup_edit
      render action: :edit, status: :unprocessable_entity
    end
  end

  def reassign
    respond_to do |format|
      format.html do
        render locals: { work_packages: @work_packages,
                         associated: WorkPackage.associated_classes_to_address_before_destruction_of(@work_packages) }
      end
      format.json do
        render json: { error_message: "Clean up of associated objects required" }, status: 420
      end
    end
  end

  def destroy
    perform_deletion
  end

  private

  def perform_deletion # rubocop:disable Metrics/AbcSize
    unless WorkPackage.cleanup_associated_before_destructing_if_required(@work_packages, current_user, params[:to_do])
      return redirect_to(action: :reassign,
                         ids: @work_packages.map(&:id),
                         delete_descendants: delete_descendants?,
                         back_url: params[:back_url])
    end

    calls = destroy_work_packages(@work_packages)
    failures = calls.reject(&:success?)

    if failures.any?
      flash[:error] = deletion_error_message(failures)
    else
      flash[:notice] = deletion_success_message(calls)
    end

    respond_to do |format|
      format.html do
        redirect_back_or_default(project_work_packages_path(@work_packages.first.project),
                                 status: :see_other)
      end
      format.json do
        failures.any? ? head(:unprocessable_entity) : head(:ok)
      end
    end
  end

  def delete_descendants_dialog_component
    if @work_packages.one?
      WorkPackages::DeleteDescendantsDialogComponent.new(work_package: @work_packages.first, back_url: params[:back_url])
    else
      WorkPackages::BulkDeleteDescendantsDialogComponent.new(work_packages: @work_packages, back_url: params[:back_url])
    end
  end

  def setup_edit
    @available_statuses = @projects.map { |p| Workflow.available_statuses(p) }.inject(&:&)
    @assignables = @responsibles = Principal.possible_assignee(@projects)
    @types = @projects.map { |project| project.enabled_types.to_a }.inject(&:&)
    @custom_fields = editable_custom_fields
  end

  # Only the custom fields that are enabled on the projects and on the types too.
  def editable_custom_fields
    @projects.map(&:all_work_package_custom_fields).inject(&:&) & custom_fields_of_type_variants
  end

  # Each project applies its own variant of a type, so the variant is resolved per project
  # before #custom_fields follows the form configuration link from there.
  def custom_fields_of_type_variants
    @projects.flat_map { |project| project.type_variants(*@types) }
             .uniq
             .flat_map { |variant| variant.custom_fields.to_a }
             .uniq
  end

  # Deletion is not all or nothing: one work package may be deleted while another
  # one fails, so every call is returned.
  def destroy_work_packages(work_packages)
    work_packages.filter_map do |work_package|
      WorkPackages::DeleteService
        .new(user: current_user,
             model: work_package.reload)
        .call(delete_descendants: delete_descendants?)
    rescue ::ActiveRecord::RecordNotFound
      # raised by #reload if work package no longer exists
      # nothing to do, work package was already deleted (eg. by a parent)
      nil
    end
  end

  # Absent means cascade, consistent with WorkPackages::DeleteService's default.
  def delete_descendants?
    ActiveModel::Type::Boolean.new.cast(params.fetch(:delete_descendants, true))
  end

  # A call also carries the descendants it deleted, next to work packages it only
  # rescheduled, so count the ones that are actually gone.
  def deletion_success_message(calls)
    count = calls.sum { |call| call.all_results.count(&:destroyed?) }

    t("work_packages.bulk.deletion_successful", count:)
  end

  def deletion_error_message(failures)
    messages = failures.map do |call|
      "#{call.result.formatted_id}: #{call.errors.full_messages.to_sentence}"
    end

    "#{t('work_packages.bulk.could_not_be_deleted')} #{messages.join(' ')}"
  end

  def attributes_for_update
    return {} unless params.has_key? :work_package

    attributes = permitted_params.update_work_package
    attributes[:custom_field_values] = transform_attributes(attributes[:custom_field_values])
    attributes = attributes_with_normalized_parent_id(attributes)
    # target_version_ids is an array param and must not be run through the generic
    # transform below (which is built for scalar "none"/blank magic values), so pull
    # it out, normalize it separately, and merge the result back in.
    target_version_ids = normalized_target_version_ids(attributes.delete(:target_version_ids))
    attributes = transform_attributes(attributes)
    attributes[:target_version_ids] = target_version_ids unless target_version_ids.nil?
    attributes
  end

  def attributes_with_normalized_parent_id(attributes)
    raw = attributes[:parent_id]
    return attributes unless WorkPackage::SemanticIdentifier.semantic_id?(raw.to_s)

    wp = WorkPackage.find_by_display_id(raw)
    # If the semantic ID hasn't resolved to a proper package, default to 0, which is an invalid value
    # that will trigger errors in the main update service
    attributes.merge(parent_id: wp ? wp.id : 0)
  end

  def user
    current_user
  end

  def transform_attributes(attributes)
    Hash(attributes)
      .compact_blank
      .transform_values { |v| Array(v).include?("none") ? "" : v }
  end
end
