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

class WorkPackageBulkUpdateService
  attr_accessor :projects,
                :work_packages

  def initialize(work_packages, projects)
    @projects      = projects
    @work_packages = work_packages
    @project       = @projects.first if @projects.size == 1
  end

  def run(params, save_wp=false)
    prepare(params)
  end

  def available_attributes
    {
      available_statuses: @available_statuses,
      assignables:        @assignables,
      responsibles:       @responsibles,
      types:              @types,
      custom_fields:      @custom_fields,
      target_project:     @target_project,
      allowed_projects:   @allowed_projects,
      copy:               @copy,
      notes:              @notes
    }
  end

  def save(params, copy = false)
    prepare(params)
    unsaved_work_package_ids = []
    moved_work_packages      = []
    @work_packages.sort!

    @work_packages.each do |work_package|
      work_package.reload

      if copy
        Redmine::Hook.call_hook(:controller_work_packages_move_before_save,
                                params:         params,
                                work_package:   work_package,
                                target_project: @target_project,
                                copy:           !!@copy)

        if r = work_package.move_to_project(@target_project,
                                            @new_type,  copy:         @copy,
                                                        attributes:   permitted_params(params),
                                                        journal_note: @notes )
          moved_work_packages << r
        else
          unsaved_work_package_ids << work_package.id
        end

      else
        work_package.add_journal(User.current, @notes)

        # filter parameters by whitelist and add defaults
        attributes = parse_params_for_bulk_work_package_attributes params, work_package.project
        work_package.assign_attributes attributes

        Redmine::Hook.call_hook(:controller_work_package_bulk_before_save,
                                params: params, work_package: work_package)
        JournalObserver.instance.send_notification = params[:send_notification] == '0' ? false : true
        unless work_package.save
          unsaved_work_package_ids << work_package.id
        end

      end
    end

    { moved_work_packages:      moved_work_packages,
      unsaved_work_package_ids: unsaved_work_package_ids,
      copy: @copy }
  end

  private

  def prepare(params)
    @work_packages.sort!
    @copy             = params.has_key? :copy
    @allowed_projects = WorkPackage.allowed_target_projects_on_move
    @target_project   = @allowed_projects.detect { |p| p.id.to_s == params[:new_project_id].to_s } if params[:new_project_id]
    @target_project   ||= @project
    @new_type         = params[:new_type_id].blank? ? nil : @target_project.types.find_by_id(params[:new_type_id])
    @notes            = params[:notes]
    @notes            ||= ''

    @custom_fields      = @projects.map { |p| p.all_work_package_custom_fields }
    .inject { |memo, c| memo & c }
    @assignables        = @projects.map(&:possible_assignees).inject { |memo, a| memo & a }
    @responsibles       = @projects.map(&:possible_responsibles).inject { |memo, a| memo & a }
    @available_statuses = @projects.map { |p| Workflow.available_statuses(p) }.inject { |memo, w| memo & w }

    if params.has_key? :copy
      @types = @target_project.types
    else
      @types = @projects.map(&:types).inject { |memo, t| memo & t }
    end
    self
  end

  def parse_params_for_bulk_work_package_attributes(params, project)
    return {} unless params.has_key? :work_package
    permitted_params = PermittedParams.new(params, User.current)
    safe_params      = permitted_params.update_work_package project: project
    attributes       = safe_params.reject { |_k, v| v.blank? }
    attributes.keys.each { |k| attributes[k] = '' if attributes[k] == 'none' }
    attributes[:custom_field_values].reject! { |_k, v| v.blank? } if attributes[:custom_field_values]
    attributes.delete :custom_field_values if not attributes.has_key?(:custom_field_values) ||
        attributes[:custom_field_values].empty?
    attributes
  end

  def permitted_params(params)
    params.permit(:copy,
                  :assigned_to_id,
                  :responsible_id,
                  :start_date,
                  :due_date,
                  :priority_id,
                  :follow,
                  :new_type_id,
                  :new_project_id,
                  ids:       [],
                  status_id: [])
  end
end
