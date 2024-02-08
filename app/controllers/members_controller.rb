#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class MembersController < ApplicationController
  include MemberHelper
  model_object Member
  before_action :find_model_object_and_project, except: [:autocomplete_for_member]
  before_action :find_project_by_project_id, only: [:autocomplete_for_member]
  before_action :authorize

  def index
    set_index_data!
  end

  def create
    overall_result = []

    find_or_create_users(send_notification: true) do |member_params|
      service_call = Members::CreateService
                       .new(user: current_user)
                       .call(member_params)

      overall_result.push(service_call)
    end

    if overall_result.empty?
      flash[:error] = I18n.t('activerecord.errors.models.member.principal_blank')
      redirect_to project_members_path(project_id: @project, status: 'all')
    elsif overall_result.all?(&:success?)
      display_success(members_added_notice(overall_result.map(&:result)))

      redirect_to project_members_path(project_id: @project, status: 'all')
    else
      display_error(overall_result.first)

      set_index_data!

      respond_to do |format|
        format.html { render 'index' }
      end
    end
  end

  def update
    service_call = Members::UpdateService
                     .new(user: current_user, model: @member)
                     .call(permitted_params.member)

    if service_call.success?
      display_success(I18n.t(:notice_successful_update))
    else
      display_error(service_call)
    end

    redirect_to project_members_path(project_id: @project,
                                     page: params[:page],
                                     per_page: params[:per_page])
  end

  def destroy
    service_call = Members::DeleteService
      .new(user: current_user, model: @member)
      .call

    if service_call.success?
      display_success(I18n.t(:notice_member_removed, user: @member.principal.name))
    end

    redirect_to project_members_path(project_id: @project)
  end

  def autocomplete_for_member
    @principals = possible_members(params[:q], 100)

    @email = suggest_invite_via_email? current_user,
                                       params[:q],
                                       (@principals | @project.principals)

    respond_to do |format|
      format.json do
        render json: build_members
      end
    end
  end

  private

  def authorize_for(controller, action)
    current_user.allowed_in_project?({ controller:, action: }, @project)
  end

  def build_members
    paths = API::V3::Utilities::PathHelper::ApiV3Path
    principals = @principals.map do |principal|
      {
        id: principal.id,
        name: principal.name,
        href: paths.send(principal.type.underscore, principal.id)
      }
    end

    if @email
      principals << { id: @email, name: I18n.t('members.invite_by_mail', mail: @email) }
    end

    principals
  end

  def members_table_options(roles)
    {
      project: @project,
      available_roles: roles,
      authorize_update: authorize_for('members', 'update'),
      is_filtered: Members::UserFilterComponent.filtered?(params)
    }
  end

  def members_filter_options(roles)
    groups = Group.all.sort
    shares = WorkPackageRole.all
    status = Members::UserFilterComponent.status_param(params)

    {
      groups:,
      roles:,
      status:,
      shares:,
      clear_url: project_members_path(@project),
      project: @project
    }
  end

  def suggest_invite_via_email?(user, query, principals)
    user.allowed_globally?(:create_user) &&
      query =~ mail_regex &&
      principals.none? { |p| p.mail == query || p.login == query } &&
      query # finally return email
  end

  def mail_regex
    /\A\S+@\S+\.\S+\z/
  end

  def set_index_data!
    set_roles_and_principles!

    @members = index_members
    @members_table_options = members_table_options @roles
    @members_filter_options = members_filter_options @roles
  end

  def set_roles_and_principles!
    @roles = ProjectRole.givable
    # Check if there is at least one principal that can be added to the project
    @principals_available = possible_members('', 1)
  end

  def possible_members(criteria, limit)
    Principal
      .possible_member(@project)
      .like(criteria)
      .limit(limit)
  end

  def index_members
    filters = params.slice(*Members::UserFilterComponent.filter_param_keys)
    filters[:project_id] = @project.id.to_s

    @members_query = Members::UserFilterComponent.query(filters)
  end

  def members_added_notice(members)
    if members.size == 1
      I18n.t(:notice_member_added, name: members.first.name)
    else
      I18n.t(:notice_members_added, number: members.size)
    end
  end

  def no_create_errors?(members)
    members.present? && members.map(&:errors).none?(&:any?)
  end

  def sort_by_groups_last(members)
    group_ids = Group.where(id: members.map(&:user_id)).pluck(:id)

    members.sort_by { |m| group_ids.include?(m.user_id) ? 1 : -1 }
  end

  def display_error(service_call)
    flash[:error] = service_call.errors.full_messages.compact.join(', ')
  end

  def display_success(message)
    flash[:notice] = message
  end
end
