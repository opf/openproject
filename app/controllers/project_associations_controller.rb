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

class ProjectAssociationsController < ApplicationController
  helper :timelines

  before_action :disable_api
  before_action :find_project_by_project_id
  before_action :authorize
  before_action :check_allows_association

  accept_key_auth :index, :show

  menu_item :project_associations

  def index
    respond_to do |format|
      format.html do
        # TODO:
        #   Project types should be ordered by position
        #   Projects and associations should be ordered by project tree
        @project_types = [nil] + ProjectType.all
        @project_associations_by_type = @project.project_associations_by_type
      end
    end
  end

  def new
    @project_association = ProjectAssociation.new(params[:project_association])
    @project_association.project_a = @project
    @associated_project_candidates_by_type = @project.associated_project_candidates_by_type
  end

  def create
    project_b_id = params[:project_association].delete :project_b_id
    @project_association = ProjectAssociation.new(params[:project_association])
    @project_association.project_a = @project
    @project_association.project_b_id = project_b_id

    check_visibility

    if @project_association.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_project_associations_path(@project)
    else
      render action: 'new'
    end
  end

  # TODO: this method should be removed once the controller no longer responds to
  # api calls
  def show
    @project_association = @project.project_associations.find(params[:id])
    check_visibility

    respond_to do |_format|
    end
  end

  def edit
    @project_association = @project.project_associations.find(params[:id])
    check_visibility

    respond_to do |format|
      format.html
    end
  end

  def update
    @project_association = @project.project_associations.find(params[:id])
    check_visibility

    if params[:project_association]
      @project_association.description = params[:project_association][:description]
    end

    check_visibility # since projects may not be edited by mass-assignement,
    # this check should be superfluous ... but who knows?!?

    if @project_association.projects.include?(@project) and @project_association.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_project_associations_path(@project)
    else
      render action: 'edit'
    end
  end

  def confirm_destroy
    @project_association = @project.project_associations.find(params[:id])
    check_visibility

    respond_to do |format|
      format.html
    end
  end

  def destroy
    @project_association = @project.project_associations.find(params[:id])
    check_visibility

    @project_association.destroy

    flash[:notice] = l(:notice_successful_delete)
    redirect_to project_project_associations_path(@project)
  end

  protected

  def check_allows_association
    render_404 unless @project.allows_association?
  end

  def check_visibility
    raise ActiveRecord::RecordNotFound unless @project_association.visible?
  end

  def default_breadcrumb
    l('timelines.project_menu.project_associations')
  end
end
