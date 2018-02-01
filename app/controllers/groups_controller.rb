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

class GroupsController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :find_group, only: [:destroy, :autocomplete_for_user,
                                    :show, :create_memberships, :destroy_membership,
                                    :edit_membership]

  # GET /groups
  # GET /groups.xml
  def index
    @groups = Group.order('lastname ASC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  do render xml: @groups end
    end
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  do render xml: @group end
    end
  end

  # GET /groups/new
  # GET /groups/new.xml
  def new
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  do render xml: @group end
    end
  end

  # GET /groups/1/edit
  def edit
    @group = Group.includes(:members, :users).find(params[:id])
  end

  # POST /groups
  # POST /groups.xml
  def create
    @group = Group.new permitted_params.group

    respond_to do |format|
      if @group.save
        flash[:notice] = l(:notice_successful_create)
        format.html do redirect_to(groups_path) end
        format.xml  do render xml: @group, status: :created, location: @group end
      else
        format.html do render action: 'new' end
        format.xml  do render xml: @group.errors, status: :unprocessable_entity end
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = Group.includes(:users).find(params[:id])

    respond_to do |format|
      if @group.update_attributes(permitted_params.group)
        flash[:notice] = l(:notice_successful_update)
        format.html do redirect_to(groups_path) end
        format.xml  do head :ok end
      else
        format.html do render action: 'edit' end
        format.xml  do render xml: @group.errors, status: :unprocessable_entity end
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group.destroy

    respond_to do |format|
      flash[:notice] = l(:notice_successful_delete)
      format.html do redirect_to(groups_url) end
      format.xml  do head :ok end
    end
  end

  def add_users
    @group = Group.includes(:users).find(params[:id])
    @users = User.includes(:memberships).where(id: params[:user_ids])
    @group.users << @users
    respond_to do |format|
      format.html do redirect_to controller: '/groups', action: 'edit', id: @group, tab: 'users' end
      format.js   do render action: 'change_members' end
    end
  end

  def remove_user
    @group = Group.includes(:users).find(params[:id])
    @group.users.delete(User.includes(:memberships).find(params[:user_id]))
    respond_to do |format|
      format.html do redirect_to controller: '/groups', action: 'edit', id: @group, tab: 'users' end
      format.js   do render action: 'change_members' end
    end
  end

  def autocomplete_for_user
    @users = User.active.not_in_group(@group).like(params[:q]).limit(100)
    render layout: false
  end

  def create_memberships
    membership_params = permitted_params.group_membership
    membership_id = membership_params[:membership_id]
    @membership = membership_id.present? ? Member.find(membership_id) : Member.new(principal: @group)

    service = ::Members::EditMembershipService.new(@membership, save: true, current_user: current_user)
    service.call(attributes: membership_params[:membership])

    respond_to do |format|
      format.html do redirect_to controller: '/groups', action: 'edit', id: @group, tab: 'memberships' end
      format.js   do render action: 'change_memberships' end
    end
  end

  alias :edit_membership :create_memberships

  def destroy_membership
    membership_params = permitted_params.group_membership
    Member.find(membership_params[:membership_id]).destroy
    respond_to do |format|
      format.html do redirect_to controller: '/groups', action: 'edit', id: @group, tab: 'memberships' end
      format.js   do render action: 'destroy_memberships' end
    end
  end

  protected

  def find_group
    @group = Group.find(params[:id])
  end

  def default_breadcrumb
    if action_name == 'index'
      t('label_group_plural')
    else
      ActionController::Base.helpers.link_to(t('label_group_plural'), groups_path)
    end
  end

  def show_local_breadcrumb
    true
  end
end
