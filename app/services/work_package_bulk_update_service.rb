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

  def run(params)
    prepare(params)
  end

  def available_attributes
    {
      statuses:         @statuses,
      types:            @types,
      priorities:       IssuePriority.active,
      assignables:      @assignables,
      responsibles:     @responsibles,
      custom_fields:    @custom_fields,
      allowed_projects: @allowed_projects,
      target_project:   @target_project,
      copy:             @copy,
      notes:            @notes
    }
  end

  def save(params, isMoveOrCopy = false)
    prepare(params)

    unsaved_work_packages = []
    moved_work_packages   = []
    @work_packages.sort!

    @work_packages.each do |work_package|
      work_package.reload

      if isMoveOrCopy
        Redmine::Hook.call_hook(:controller_work_packages_move_before_save,
                                params:         params,
                                work_package:   work_package,
                                target_project: @target_project,
                                copy:           !!@copy)

        moved_wp = work_package.move_to_project(@target_project,
                                                @target_type,
                                                copy:         @copy,
                                                attributes:   permit_params_for_move_or_copy(params),
                                                journal_note: @notes)

        if moved_wp
          moved_work_packages << moved_wp
        else
          unsaved_work_packages << work_package
        end
      else
        work_package.add_journal(User.current, @notes)

        # filter parameters by whitelist and add defaults
        attributes = permit_params_for_edit params, work_package.project
        work_package.assign_attributes attributes

        Redmine::Hook.call_hook(:controller_work_package_bulk_before_save,
                                params: params, work_package: work_package)
        JournalObserver.instance.send_notification = params[:send_notification] == '0' ? false : true
        unless work_package.save
          unsaved_work_packages << work_package
        end
      end
    end

    {
      moved_work_packages:   moved_work_packages,
      unsaved_work_packages: unsaved_work_packages,
      copy: @copy
    }
  end

  private

  def prepare(params)
    @work_packages.sort!
    @copy             = params.has_key? :copy
    @allowed_projects = WorkPackage.allowed_target_projects_on_move
    if params[:new_project_id]
      @target_project = @allowed_projects.detect { |p| p.id.to_s == params[:new_project_id].to_s }
    end

    # allowed values will be derived from the effective project
    effective_projects = @target_project ? [@target_project] : @projects

    @custom_fields = intersect_arrays effective_projects.map(&:all_work_package_custom_fields)
    @assignables   = intersect_arrays effective_projects.map(&:possible_assignees)
    @responsibles  = intersect_arrays effective_projects.map(&:possible_responsibles)
    @statuses      = intersect_arrays effective_projects.map { |p| Workflow.available_statuses(p) }
    @types         = intersect_arrays effective_projects.map(&:types)

    @target_project ||= @project
    @target_type = params[:new_type_id].nil? ? nil : @types.detect { |t| t.id.to_s == params[:new_type_id].to_s }
    @notes       = params[:notes] || ''

    self
  end

  def permit_params_for_edit(params, project)
    return {} unless params.has_key? :work_package
    permitted_params = PermittedParams.new(params, User.current)
    safe_params      = permitted_params.update_work_package project: project
    attributes       = safe_params.reject { |_k, v| v.blank? }
    attributes.keys.each { |k| attributes[k] = '' if attributes[k] == 'none' }
    attributes[:custom_field_values].reject! { |_k, v| v.blank? } if attributes[:custom_field_values]
    if not attributes.has_key?(:custom_field_values) or attributes[:custom_field_values].empty?
      attributes.delete :custom_field_values
    end
    attributes
  end

  def permit_params_for_move_or_copy(params)
    params.permit(:copy,
                  :assigned_to_id,
                  :responsible_id,
                  :start_date,
                  :due_date,
                  :priority_id,
                  :status_id,
                  :follow,
                  :new_type_id,
                  :new_project_id,
                  ids: [])
  end

  def intersect_arrays(arrays)
    arrays.inject { |memo, array| memo & array }
  end
end
