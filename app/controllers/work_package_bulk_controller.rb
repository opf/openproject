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
  before_filter :find_issues, only: [:edit, :update]
  before_filter :authorize

  include JournalsHelper
  include ProjectsHelper
  include CustomFieldsHelper
  include RelationsHelper
  include QueriesHelper
  include IssuesHelper

  def edit
    @issues.sort!
    @available_statuses = @projects.map{|p|Workflow.available_statuses(p)}.inject{|memo,w|memo & w}
    @custom_fields = @projects.map{|p|p.all_work_package_custom_fields}.inject{|memo,c|memo & c}
    @assignables = @projects.map(&:assignable_users).inject{|memo,a| memo & a}
    @types = @projects.map(&:types).inject{|memo,t| memo & t}
  end

  def update
    @issues.sort!
    attributes = parse_params_for_bulk_work_package_attributes(params)

    unsaved_issue_ids = []
    @issues.each do |issue|
      issue.reload
      issue.add_journal(User.current, params[:notes])
      issue.safe_attributes = attributes
      call_hook(:controller_issues_bulk_edit_before_save, { :params => params, :issue => issue })
      JournalObserver.instance.send_notification = params[:send_notification] == '0' ? false : true
      unless issue.save
        # Keep unsaved issue ids to display them in flash error
        unsaved_issue_ids << issue.id
      end
    end
    set_flash_from_bulk_issue_save(@issues, unsaved_issue_ids)
    redirect_back_or_default({:controller => '/work_packages', :action => 'index', :project_id => @project})
  end

private

  def parse_params_for_bulk_work_package_attributes(params)
    attributes = (params[:issue] || {}).reject {|k,v| v.blank?}
    attributes.keys.each {|k| attributes[k] = '' if attributes[k] == 'none'}
    attributes[:custom_field_values].reject! {|k,v| v.blank?} if attributes[:custom_field_values]
    attributes.delete :custom_field_values if not attributes.has_key?(:custom_field_values) or attributes[:custom_field_values].empty?
    attributes
  end
end
