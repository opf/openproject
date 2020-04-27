#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class GroupsController < ApplicationController
  include GroupsHelper
  layout 'admin'

  helper_method :gon

  before_action :require_admin
  before_action :find_group, only: %i[destroy show create_memberships destroy_membership
                                      edit_membership add_users]

  # GET /groups
  # GET /groups.xml
  def index
    @groups = Group.order(Arel.sql('lastname ASC'))

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

    set_filters_for_user_autocompleter
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
      if @group.update(permitted_params.group)
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
    call = @group
      .add_members!(User.where(id: params[:user_ids]).pluck(:id))

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
    else
      call.apply_flash_message!(flash)
    end

    redirect_to controller: '/groups', action: 'edit', id: @group, tab: 'users'
  end

  def remove_user
    @group = Group.includes(:users).find(params[:id])
    @group.users.delete(User.includes(:memberships).find(params[:user_id]))

    I18n.t :notice_successful_update
    redirect_to controller: '/groups', action: 'edit', id: @group, tab: 'users'
  end

  def create_memberships
    membership_params = permitted_params.group_membership
    membership_id = membership_params[:membership_id]

    if membership_id.present?
      key = :membership
      @membership = Member.find(membership_id)
    else
      key = :new_membership
      @membership = Member.new(principal: @group)
    end

    service = ::Members::EditMembershipService.new(@membership, save: true, current_user: current_user)
    result = service.call(attributes: membership_params[key])

    if result.success?
      flash[:notice] = I18n.t :notice_successful_update
    else
      flash[:error] = result.errors.full_messages.join("\n")
    end
    redirect_to controller: '/groups', action: 'edit', id: @group, tab: 'memberships'
  end

  alias :edit_membership :create_memberships

  def destroy_membership
    membership_params = permitted_params.group_membership
    Member.find(membership_params[:membership_id]).destroy

    flash[:notice] = I18n.t :notice_successful_delete
    redirect_to controller: '/groups', action: 'edit', id: @group, tab: 'memberships'
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
