#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

class WorkPackageBulkController < ApplicationController
  before_filter :disable_api
  before_filter :find_work_packages, only: [:edit, :update]
  before_filter :authorize

  include JournalsHelper
  include ProjectsHelper
  include CustomFieldsHelper
  include RelationsHelper
  include QueriesHelper
  include IssuesHelper

  def edit
    @work_packages.sort!
    @available_statuses = @projects.map{|p|Workflow.available_statuses(p)}.inject{|memo,w|memo & w}
    @custom_fields = @projects.map{|p|p.all_work_package_custom_fields}.inject{|memo,c|memo & c}
    @assignables = @projects.map(&:assignable_users).inject{|memo,a| memo & a}
    @types = @projects.map(&:types).inject{|memo,t| memo & t}
  end

  def update
    @work_packages.sort!
    attributes = parse_params_for_bulk_work_package_attributes(params)

    unsaved_work_package_ids = []
    @work_packages.each do |work_package|
      work_package.reload
      work_package.add_journal(User.current, params[:notes])
      work_package.safe_attributes = attributes
      call_hook(:controller_work_package_bulk_before_save, { params: params, work_package: work_package })
      JournalObserver.instance.send_notification = params[:send_notification] == '0' ? false : true
      unless work_package.save
        unsaved_work_package_ids << work_package.id
      end
    end
    set_flash_from_bulk_save(@work_packages, unsaved_work_package_ids)
    redirect_back_or_default({controller: '/work_packages', action: :index, project_id: @project})
  end

private

  def parse_params_for_bulk_work_package_attributes(params)
    attributes = (params[:work_package] || {}).reject {|k,v| v.blank?}
    attributes.keys.each {|k| attributes[k] = '' if attributes[k] == 'none'}
    attributes[:custom_field_values].reject! {|k,v| v.blank?} if attributes[:custom_field_values]
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
                        :count => unsaved_work_package_ids.size,
                        :total => work_packages.size,
                        :ids => '#' + unsaved_work_package_ids.join(', #'))
    end
  end
end
