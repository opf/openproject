# frozen_string_literal: true

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

class CategoriesController < ApplicationController
  menu_item :settings_categories

  before_action :find_category_and_project, except: %i[new create]
  before_action :find_project, only: %i[new create]
  before_action :authorize

  def new
    @category = @project.categories.build
  end

  def create
    @category = @project.categories.build
    @category.attributes = permitted_params.category

    if @category.save
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to project_settings_categories_path(@project)
    else
      render action: :new, status: :unprocessable_entity
    end
  end

  def update
    @category.attributes = permitted_params.category
    if @category.save
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to project_settings_categories_path(@project)
    else
      render action: :edit, status: :unprocessable_entity
    end
  end

  def destroy # rubocop:disable Metrics/AbcSize
    @issue_count = @category.work_packages.size
    if @issue_count == 0
      # No issue assigned to this category
      @category.destroy
      redirect_to project_settings_categories_path(@project), status: :see_other
      return
    elsif params[:todo]
      reassign_to = @project.categories.find_by(id: params[:reassign_to_id]) if params[:todo] == "reassign"
      @category.destroy(reassign_to)
      redirect_to project_settings_categories_path(@project), status: :see_other
      return
    end
    @categories = @project.categories - [@category]
    render status: :unprocessable_entity
  end

  private

  def find_category_and_project
    @category = Category.find(params[:id])
    @project = @category.project
  end

  def find_project
    @project = Project.visible.find(params[:project_id])
  end
end
