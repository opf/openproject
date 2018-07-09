#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackages::BulkController < ApplicationController
  before_action :find_work_packages
  before_action :authorize

  include ProjectsHelper
  include CustomFieldsHelper
  include RelationsHelper
  include QueriesHelper
  include IssuesHelper
  include ::WorkPackages::Shared::UpdateAncestors

  def edit
    @available_statuses = @projects.map { |p| Workflow.available_statuses(p) }.inject { |memo, w| memo & w }
    @custom_fields = @projects.map(&:all_work_package_custom_fields).inject { |memo, c| memo & c }
    @assignables = @projects.map(&:possible_assignees).inject { |memo, a| memo & a }
    @responsibles = @projects.map(&:possible_responsibles).inject { |memo, a| memo & a }
    @types = @projects.map(&:types).inject { |memo, t| memo & t }
  end

  def update
    unsaved_work_package_ids = []
    saved_work_packages = []


    @work_packages.each do |work_package|
      work_package.reload
      work_package.add_journal(User.current, params[:notes])

      # filter parameters by whitelist and add defaults
      attributes = parse_params_for_bulk_work_package_attributes params, work_package.project
      work_package.assign_attributes attributes

      call_hook(:controller_work_packages_bulk_edit_before_save, params: params, work_package: work_package)
      JournalManager.send_notification = params[:send_notification] == '0' ? false : true
      if work_package.save
        saved_work_packages << work_package
      else
        unsaved_work_package_ids << work_package.id
      end
    end

    update_ancestors(saved_work_packages)
    set_flash_from_bulk_save(@work_packages, unsaved_work_package_ids)
    redirect_back_or_default(controller: '/work_packages', action: :index, project_id: @project)
  end

  def destroy
    unless WorkPackage.cleanup_associated_before_destructing_if_required(@work_packages, current_user, params[:to_do])

      respond_to do |format|
        format.html do
          render locals: { work_packages: @work_packages,
                           associated: WorkPackage.associated_classes_to_address_before_destruction_of(@work_packages) }
        end
        format.json do
          render json: { error_message: 'Clean up of associated objects required' }, status: 420
        end
      end

    else

      destroy_work_packages(@work_packages)

      respond_to do |format|
        format.html do
          redirect_back_or_default(project_work_packages_path(@work_packages.first.project))
        end
        format.json do
          head :ok
        end
      end
    end
  end

  private

  def destroy_work_packages(work_packages)
    work_packages.each do |work_package|
      begin
        WorkPackages::DestroyService
          .new(user: current_user, work_package: work_package.reload)
          .call
      rescue ::ActiveRecord::RecordNotFound
        # raised by #reload if work package no longer exists
        # nothing to do, work package was already deleted (eg. by a parent)
      end
    end
  end

  def parse_params_for_bulk_work_package_attributes(params, project)
    return {} unless params.has_key? :work_package

    safe_params = permitted_params.update_work_package project: project
    attributes = safe_params.reject { |_k, v| v.blank? }
    attributes.keys.each do |k| attributes[k] = '' if attributes[k] == 'none' end
    attributes[:custom_field_values].reject! { |_k, v| v.blank? } if attributes[:custom_field_values]
    attributes.delete :custom_field_values if not attributes.has_key?(:custom_field_values) or attributes[:custom_field_values].empty?
    attributes
  end

  # Sets the `flash` notice or error based the number of work packages that did not save
  #
  # @param [Array, WorkPackage] work_packages all of the saved and unsaved WorkPackages
  # @param [Array, Integer] unsaved_work_package_ids the WorkPackage ids that were not saved
  def set_flash_from_bulk_save(work_packages, unsaved_work_package_ids)
    if unsaved_work_package_ids.empty?
      flash[:notice] = l(:notice_successful_update) unless work_packages.empty?
    else
      flash[:error] = l(:notice_failed_to_save_work_packages,
                        count: unsaved_work_package_ids.size,
                        total: work_packages.size,
                        ids: '#' + unsaved_work_package_ids.join(', #'))
    end
  end

  def user
    current_user
  end

  def default_breadcrumb
    l(:label_work_package_plural)
  end
end
