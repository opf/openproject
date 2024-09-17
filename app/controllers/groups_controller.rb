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

class GroupsController < ApplicationController
  include GroupsHelper
  layout "admin"

  before_action :require_admin, except: %i[show]
  no_authorization_required! :show

  before_action :find_group, only: %i[destroy update show create_memberships destroy_membership
                                      edit_membership add_users]

  def index
    @groups = Group.order(Arel.sql("lastname ASC"))
  end

  def show
    @group_users = group_members
    render layout: "no_menu"
  end

  def new
    @group = Group.new
  end

  def edit
    @group = Group.includes(:members, :users).find(params[:id])
  end

  def create
    service_call = Groups::CreateService
                     .new(user: current_user)
                     .call(permitted_params.group)

    @group = service_call.result

    if service_call.success?
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to(groups_path)
    else
      render action: :new
    end
  end

  def update
    service_call = Groups::UpdateService
                   .new(user: current_user, model: @group)
                   .call(permitted_params.group)

    if service_call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to(groups_path)
    else
      render action: "edit"
    end
  end

  def destroy
    Groups::DeleteService
      .new(user: current_user, model: @group)
      .call

    flash[:info] = I18n.t(:notice_deletion_scheduled)
    redirect_to(action: :index)
  end

  def add_users
    service_call = Groups::UpdateService
                   .new(user: current_user, model: @group)
                   .call(user_ids: @group.user_ids + Array(params[:user_ids]).map(&:to_i))

    respond_users_altered(service_call)
  end

  def remove_user
    @group = Group.includes(:group_users).find(params[:id])

    service_call = Groups::UpdateService
                   .new(user: current_user, model: @group)
                   .call(user_ids: @group.user_ids - Array(params[:user_id]).map(&:to_i))

    respond_users_altered(service_call)
  end

  def create_memberships
    membership_params = permitted_params.group_membership[:membership]

    service_call = Members::CreateService
                   .new(user: current_user)
                   .call(membership_params.merge(principal: @group))

    respond_membership_altered(service_call)
  end

  def edit_membership
    membership_params = permitted_params.group_membership

    @membership = Member.find(membership_params[:membership_id])

    service_call = Members::UpdateService
                   .new(model: @membership, user: current_user)
                   .call(membership_params[:membership])

    respond_membership_altered(service_call)
  end

  def destroy_membership
    member = Member.find(params[:membership_id])
    Members::DeleteService
      .new(model: member, user: current_user)
      .call

    flash[:notice] = I18n.t :notice_successful_delete
    redirect_to controller: "/groups", action: "edit", id: @group, tab: redirected_to_tab(member)
  end

  protected

  def find_group
    @group = Group.find(params[:id])
  end

  def group_members
    if visible_group_members?
      @group.users
    else
      User.none
    end
  end

  def visible_group_members?
    current_user.admin? ||
      current_user.allowed_in_any_project?(:manage_members) ||
      Group.in_project(Project.allowed_to(current_user, :view_members)).exists?
  end

  def show_local_breadcrumb
    false
  end

  def respond_membership_altered(service_call)
    if service_call.success?
      flash[:notice] = I18n.t :notice_successful_update
    else
      flash[:error] = service_call.errors.full_messages.join("\n")
    end

    redirect_to controller: "/groups", action: "edit", id: @group, tab: redirected_to_tab(service_call.result)
  end

  def redirected_to_tab(membership)
    if membership.project
      "memberships"
    else
      "global_roles"
    end
  end

  def respond_users_altered(service_call)
    if service_call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
    else
      service_call.apply_flash_message!(flash)
    end

    redirect_to controller: "/groups", action: "edit", id: @group, tab: "users"
  end
end
