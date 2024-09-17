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

  def edit
    setup_edit
  end

  def update
    @call = ::WorkPackages::Bulk::UpdateService
      .new(user: current_user, work_packages: @work_packages)
      .call(attributes_for_update)

    if @call.success?
      flash[:notice] = t(:notice_successful_update)
      redirect_back_or_default(controller: "/work_packages", action: :index, project_id: @project)
    else
      flash[:error] = bulk_error_message(@work_packages, @call)
      setup_edit
      render action: :edit
    end
  end

  def destroy
    if WorkPackage.cleanup_associated_before_destructing_if_required(@work_packages, current_user, params[:to_do])
      destroy_work_packages(@work_packages)

      respond_to do |format|
        format.html do
          redirect_back_or_default(project_work_packages_path(@work_packages.first.project))
        end
        format.json do
          head :ok
        end
      end
    else
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
  end

  private

  def setup_edit
    @available_statuses = @projects.map { |p| Workflow.available_statuses(p) }.inject(&:&)
    @assignables = @responsibles = Principal.possible_assignee(@projects)
    @types = @projects.map(&:types).inject(&:&)

    # Display only the custom fields that are enabled on the projects and on types too.
    @custom_fields =
      @projects.map(&:all_work_package_custom_fields).inject(&:&) &
      WorkPackageCustomField.joins(:types).where(types: @types)
  end

  def destroy_work_packages(work_packages)
    work_packages.each do |work_package|
      WorkPackages::DeleteService
        .new(user: current_user,
             model: work_package.reload)
        .call
    rescue ::ActiveRecord::RecordNotFound
      # raised by #reload if work package no longer exists
      # nothing to do, work package was already deleted (eg. by a parent)
    end
  end

  def attributes_for_update
    return {} unless params.has_key? :work_package

    attributes = permitted_params.update_work_package
    attributes[:custom_field_values] = transform_attributes(attributes[:custom_field_values])
    transform_attributes(attributes)
  end

  def user
    current_user
  end

  def default_breadcrumb
    I18n.t(:label_work_package_plural)
  end

  def transform_attributes(attributes)
    Hash(attributes)
      .compact_blank
      .transform_values { |v| Array(v).include?("none") ? "" : v }
  end
end
