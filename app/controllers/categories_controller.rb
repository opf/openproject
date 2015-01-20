#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

class CategoriesController < ApplicationController
  menu_item :settings
  model_object Category
  before_filter :find_model_object, except: [:new, :create]
  before_filter :find_project_from_association, except: [:new, :create]
  before_filter :find_project, only: [:new, :create]
  before_filter :authorize

  def new
    @category = @project.categories.build
  end

  def create
    @category = @project.categories.build
    @category.safe_attributes = params[:category]

    if @category.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_to controller: '/projects', action: 'settings', tab: 'categories', id: @project
        end
        format.js do
          render locals: { project: @project, category: @category }
        end
      end
    else
      respond_to do |format|
        format.html { render action: :new }
        format.js do
          render(:update) { |page| page.alert(@category.errors.full_messages.join('\n')) }
        end
      end
    end
  end

  def edit
    @category.safe_attributes = params[:category]
  end

  def update
    @category.safe_attributes = params[:category]
    if @category.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to controller: '/projects', action: 'settings', tab: 'categories', id: @project
    else
      render action: 'edit'
    end
  end

  def destroy
    @issue_count = @category.work_packages.size
    if @issue_count == 0
      # No issue assigned to this category
      @category.destroy
      redirect_to controller: '/projects', action: 'settings', id: @project, tab: 'categories'
      return
    elsif params[:todo]
      reassign_to = @project.categories.find_by_id(params[:reassign_to_id]) if params[:todo] == 'reassign'
      @category.destroy(reassign_to)
      redirect_to controller: '/projects', action: 'settings', id: @project, tab: 'categories'
      return
    end
    @categories = @project.categories - [@category]
  end

  private

  # Wrap ApplicationController's find_model_object method to set
  # @category instead of just @category
  def find_model_object
    super
    @category = @object
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
