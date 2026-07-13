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

module Admin
  class DepartmentsController < ::ApplicationController
    include OpTurbo::ComponentStream
    include GroupsHelper

    layout :admin_or_frame_layout

    menu_item :departments

    # TODO: We will check for users permission here
    before_action :require_admin
    before_action :find_group,
                  only: %i[show edit new_user add_user remove_user update destroy change_parent_dialog change_parent
                           create_memberships edit_membership destroy_membership]

    def index
      @groups = Group.with_detail.organizational_units.visible.order(:lastname)
    end

    def new_user
      @groups = Group.with_detail.organizational_units.visible.order(:lastname)
      @add_user = true
      render action: :index
    end

    def add_user # rubocop:disable Metrics/AbcSize
      result = ::Departments::AddUserService
        .new(@group, user: current_user)
        .call(
          user_id: params[:user_id],
          remove_from_previous_department: params[:remove_from_previous_department] == "true"
        )

      if result.success?
        flash[:notice] = I18n.t("departments.flash.user_added")
        redirect_to admin_department_path(@group), status: :see_other
      elsif result.result.is_a?(Group)
        respond_with_dialog(
          Admin::Departments::MoveUserDialogComponent.new(
            user: User.find(params[:user_id]),
            from_department: result.result,
            to_department: @group
          )
        )
      else
        flash[:error] = result.errors.full_messages.join("\n")
        redirect_to admin_department_path(@group), status: :see_other
      end
    end

    def new_department
      @group = Group.visible.with_detail.organizational_units.find(params[:parent_id]) if params[:parent_id].present?
      @groups = Group.with_detail.organizational_units.visible.order(:lastname)
      @add_subgroup = true
      render action: :index
    end

    def add_department
      service_call = ::Groups::CreateService
        .new(user: current_user)
        .call(permitted_params.group.merge(organizational_unit: true))

      respond_department_created(service_call)
    end

    def remove_user
      service_call = ::Groups::UpdateService
        .new(user: current_user, model: @group)
        .call(remove_user_ids: [params[:user_id]])

      if service_call.success?
        flash[:notice] = I18n.t("departments.flash.user_removed")
      else
        flash[:error] = service_call.errors.full_messages.join("\n")
      end
      redirect_to admin_department_path(@group), status: :see_other
    end

    def change_parent_dialog
      departments = Group.with_detail.organizational_units.visible.order(:lastname)
      respond_with_dialog(
        Admin::Departments::ChangeParentDialogComponent.new(department: @group, departments:)
      )
    end

    def change_parent
      new_parent_id = parse_new_parent_id(params[:new_parent_id])
      service_call = ::Groups::UpdateService
        .new(user: current_user, model: @group)
        .call(parent_id: new_parent_id)

      respond_parent_changed(service_call)
    end

    def edit_organization_name
      replace_via_turbo_stream(component: Admin::Departments::OrganizationNameFormComponent.new)
      respond_with_turbo_streams
    end

    def cancel_edit_organization_name
      replace_via_turbo_stream(component: Admin::Departments::OrganizationNameComponent.new)
      respond_with_turbo_streams
    end

    def update_organization_name
      ::Settings::UpdateService
        .new(user: current_user)
        .call(organization_name: params[:organization_name])

      replace_via_turbo_stream(component: Admin::Departments::OrganizationNameComponent.new)
      respond_with_turbo_streams
    end

    # old groups interface that we adapted for departments.

    def show
      @groups = Group.with_detail.organizational_units.visible.order(:lastname)
      render action: :index
    end

    def edit; end

    def update
      service_call = ::Groups::UpdateService
                     .new(user: current_user, model: @group)
                     .call(permitted_params.group)

      if service_call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to edit_admin_department_path(@group), status: :see_other
      else
        render action: :edit, status: :unprocessable_entity
      end
    end

    def destroy
      redirect_target = @group.parent

      ::Groups::DeleteService
        .new(user: current_user, model: @group)
        .call

      flash[:info] = I18n.t(:notice_deletion_scheduled)
      redirect_to redirect_target ? admin_department_path(redirect_target) : admin_departments_path, status: :see_other
    end

    def create_memberships
      membership_params = permitted_params.group_membership[:membership]

      service_call = ::Members::CreateService
                     .new(user: current_user)
                     .call(membership_params.merge(principal: @group))

      respond_membership_altered(service_call)
    end

    def edit_membership
      membership_params = permitted_params.group_membership

      @membership = Member.find(membership_params[:membership_id])

      service_call = ::Members::UpdateService
                     .new(model: @membership, user: current_user)
                     .call(membership_params[:membership])

      respond_membership_altered(service_call)
    end

    def destroy_membership
      member = Member.find(params[:membership_id])
      ::Members::DeleteService
        .new(model: member, user: current_user)
        .call

      flash[:notice] = I18n.t(:notice_successful_delete)
      redirect_to edit_admin_department_path(@group, tab: redirected_to_tab(member)), status: :see_other
    end

    private

    def admin_or_frame_layout
      return "turbo_rails/frame" if turbo_frame_request?

      "admin"
    end

    def redirect_target_for(department)
      department.parent || department
    end

    def find_group
      @group = Group.visible.organizational_units.includes(:members, :users, :group_detail).find(params[:id])
    end

    def parse_new_parent_id(input)
      return nil if input.blank?

      value = MultiJSON.load(Array(input).first, symbolize_keys: true)[:value]
      value.presence
    end

    def respond_parent_changed(service_call)
      if service_call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to admin_department_path(service_call.result.parent || service_call.result), status: :see_other
      else
        flash[:error] = service_call.errors.full_messages.join("\n")
        redirect_to admin_department_path(@group), status: :see_other
      end
    end

    def respond_department_created(service_call)
      if service_call.success?
        flash[:notice] = I18n.t("departments.flash.department_created")
        redirect_to admin_department_path(redirect_target_for(service_call.result)), status: :see_other
      else
        flash[:error] = service_call.errors.full_messages.join("\n")
        redirect_back_or_to(admin_departments_path)
      end
    end

    def respond_membership_altered(service_call)
      if service_call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
      else
        flash[:error] = service_call.errors.full_messages.join("\n")
      end

      redirect_to edit_admin_department_path(@group, tab: redirected_to_tab(service_call.result))
    end

    def redirected_to_tab(membership)
      if membership.project
        "memberships"
      else
        "global_roles"
      end
    end
  end
end
