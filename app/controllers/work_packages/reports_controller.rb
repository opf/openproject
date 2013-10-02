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

class WorkPackages::ReportsController < ApplicationController
  menu_item :summary_field, :only => [:report, :report_details]
  before_filter :find_project_by_project_id, :authorize, :find_statuses

  class << self; attr_accessor :report_types end
  def self.add_report(params)
    self.report_types ||= {}
    self.report_types[params[:type]] = params
  end

  add_report type: "subproject",
             field: "project_id",
             rows: lambda{|project| project.descendants.visible},
             data: lambda{|project| WorkPackage.by_subproject(project) || []},
             report_title: l(:label_subproject_plural)

  add_report type: "author",
             field: "author_id",
             rows: lambda{|project| project.members.collect { |m| m.user }.sort},
             data: lambda{|project| WorkPackage.by_author(project)},
             report_title: WorkPackage.human_attribute_name(:author)

  add_report type: "assigned_to",
             field: "assigned_to_id",
             rows: lambda{|project| project.members.collect { |m| m.user }.sort},
             data: lambda{|project| WorkPackage.by_assigned_to(project)},
             report_title: WorkPackage.human_attribute_name(:assigned_to)

  add_report type: "type",
             field: "type_id",
             rows: lambda{|project| project.types},
             data: lambda{|project| WorkPackage.by_type(project)},
             report_title: WorkPackage.human_attribute_name(:type)

  add_report type: "version",
             field: "fixed_version_id",
             rows: lambda{|project| project.shared_versions.sort},
             data: lambda{|project| WorkPackage.by_version(project)},
             report_title: WorkPackage.human_attribute_name(:version)

  add_report type: "priority",
             field: "priority_id",
             rows: lambda{|project| IssuePriority.all},
             data: lambda{|project| WorkPackage.by_priority(project)},
             report_title: WorkPackage.human_attribute_name(:priority)

  add_report type: "category",
             field: "category_id",
             rows: lambda{|project| project.categories},
             data: lambda{|project| WorkPackage.by_category(project)},
             report_title: WorkPackage.human_attribute_name(:category)

  def report
    @types = @project.types
    @versions = @project.shared_versions.sort
    @priorities = IssuePriority.all
    @categories = @project.categories
    @assignees = @project.members.collect { |m| m.user }.sort
    @authors = @project.members.collect { |m| m.user }.sort
    @subprojects = @project.descendants.visible

    @work_packages_by_type = WorkPackage.by_type(@project)
    @work_packages_by_version = WorkPackage.by_version(@project)
    @work_packages_by_priority = WorkPackage.by_priority(@project)
    @work_packages_by_category = WorkPackage.by_category(@project)
    @work_packages_by_assigned_to = WorkPackage.by_assigned_to(@project)
    @work_packages_by_author = WorkPackage.by_author(@project)
    @work_packages_by_subproject = WorkPackage.by_subproject(@project) || []
  end

  def report_details
    report = self.class.report_types[params[:detail]]

    respond_to do |format|
      if report
        @field = report[:field]
        @rows = report[:rows].call(@project)
        @data = report[:data].call(@project)
        @report_title = report[:title]
        format.html {}
      else
        format.html { redirect_to report_project_work_packages_path(@project) }
      end
    end
  end

  private

  def find_statuses
    @statuses = Status.order('position')
  end

  def default_breadcrumb
    l(:label_summary)
  end


end
