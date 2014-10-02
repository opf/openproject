#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackages::BulkController < ApplicationController
  before_filter :find_work_packages
  before_filter :authorize

  include JournalsHelper
  include ProjectsHelper
  include CustomFieldsHelper
  include RelationsHelper
  include QueriesHelper
  include IssuesHelper

  def edit
    WorkPackageBulkUpdateService.new(@work_packages, @projects).run(params)
    .available_attributes.each do |key, value|
      self.instance_variable_set(:"@#{key}", value)
    end
  end

  def update
    WorkPackageBulkUpdateService.new(@work_packages, @projects).save(params).each do |key, value|
      self.instance_variable_set(:"@#{key}", value)
    end

    set_flash_from_bulk_save(@work_packages, @unsaved_work_package_ids)
    redirect_back_or_default({controller: '/work_packages', action: :index, project_id: @project}, false)
  end

  def destroy
    unless WorkPackage.cleanup_associated_before_destructing_if_required(@work_packages, current_user, params[:to_do])

      respond_to do |format|
        format.html { render :locals => { work_packages: @work_packages,
                                          associated: WorkPackage.associated_classes_to_address_before_destruction_of(@work_packages) }
                    }
        format.json { render json: { error_message: 'Clean up of associated objects required'}, status: 420 }
      end

    else

      destroy_work_packages(@work_packages)

      respond_to do |format|
        format.html { redirect_back_or_default(project_work_packages_path(@work_packages.first.project)) }
        format.json { head :ok }
      end
    end
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

private

  def destroy_work_packages(work_packages)
    work_packages.each do |work_package|
      begin
        work_package.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
        # raised by #reload if work package no longer exists
        # nothing to do, work package was already deleted (eg. by a parent)
      end
    end
  end

  def default_breadcrumb
    l(:label_work_package_plural)
  end
end
