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

class WorkPackages::ContextMenusController < ApplicationController

  def index
    @work_packages = WorkPackage.visible.all(order: "#{WorkPackage.table_name}.id",
                                             conditions: {id: params[:ids]},
                                             include: :project)

    if (@work_packages.size == 1)
      @work_package = @work_packages.first
      @allowed_statuses = @work_package.new_statuses_allowed_to(User.current)
    else
      @allowed_statuses = @work_packages.map do |i|
        i.new_statuses_allowed_to(User.current)
      end.inject do |memo,s|
        memo & s
      end
    end

    @projects = @work_packages.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1

    @can = {:edit => User.current.allowed_to?(:edit_work_packages, @projects),
            :log_time => (@project && User.current.allowed_to?(:log_time, @project)),
            :update => (User.current.allowed_to?(:edit_work_packages, @projects) || (User.current.allowed_to?(:change_status, @projects) && !@allowed_statuses.blank?)),
            :move => (@project && User.current.allowed_to?(:move_work_packages, @project)),
            :copy => (@work_package && @project.types.include?(@work_package.type) && User.current.allowed_to?(:add_work_packages, @project)),
            :delete => User.current.allowed_to?(:delete_work_packages, @projects)
            }
    if @project
      @assignables = @project.assignable_users
      @assignables << @work_package.assigned_to if @work_package && @work_package.assigned_to && !@assignables.include?(@work_package.assigned_to)
      @types = @project.types
    else
      #when multiple projects, we only keep the intersection of each set
      @assignables = @projects.map(&:assignable_users).inject{|memo,a| memo & a}
      @types = @projects.map(&:types).inject{|memo,t| memo & t}
    end

    @priorities = IssuePriority.all.reverse
    @statuses = Status.find(:all, :order => 'position')
    @back = back_url

    render :layout => false
  end
end
