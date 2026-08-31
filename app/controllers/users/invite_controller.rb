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
class Users::InviteController < ApplicationController
  include OpTurbo::ComponentStream
  include MemberHelper

  authorize_with_permission :manage_members, global: true
  before_action :set_project, only: :start_dialog

  def start_dialog
    respond_with_dialog(
      Users::Invitation::DialogComponent.new(form_model, project: @project)
    )
  end

  def step
    if form_model.valid?(validation_context) || params[:step] == "initial"
      respond_with_next_step
    else
      handle_errors_in_step
    end
  end

  private

  def handle_errors_in_step
    case params[:step]
    when "project"
      replace_via_turbo_stream(component: Users::Invitation::ProjectStep::FormComponent.new(form_model))
      respond_with_turbo_streams
    when "principal"
      replace_via_turbo_stream(component: Users::Invitation::PrincipalStep::FormComponent.new(form_model))
      respond_with_turbo_streams
    else
      render_400 message: "Invalid step"
    end
  end

  def respond_with_next_step # rubocop:disable Metrics/AbcSize
    case params[:step]
    when "initial"
      update_dialog_title_via_turbo_stream(Users::Invitation::DialogComponent::DIALOG_ID,
                                           new_title: I18n.t("users.invite_user_modal.title.invite"))
      replace_via_turbo_stream(component: Users::Invitation::ProjectStep::FormComponent.new(form_model))
      replace_via_turbo_stream(component: Users::Invitation::ProjectStep::FooterComponent.new(form_model))
      respond_with_turbo_streams
    when "project"
      update_dialog_title_via_turbo_stream(Users::Invitation::DialogComponent::DIALOG_ID, new_title: dialog_title)
      replace_via_turbo_stream(component: Users::Invitation::PrincipalStep::FormComponent.new(form_model))
      replace_via_turbo_stream(component: Users::Invitation::PrincipalStep::FooterComponent.new(form_model))
      respond_with_turbo_streams
    when "principal"
      create_invitation
    else
      render_400 message: "Invalid step"
    end
  end

  def create_invitation # rubocop:disable Metrics/AbcSize
    call = create_member_call

    if call.success?
      render_success_flash_message_via_turbo_stream(
        message: I18n.t("users.invite_user_modal.success_message.#{form_model.principal_type.underscore}",
                        project: form_model.project.name)
      )
      close_dialog_via_turbo_stream(Users::Invitation::DialogComponent::DIALOG_ID,
                                    additional: { user_id: call.result.user_id })
    else
      replace_via_turbo_stream(component: Users::Invitation::PrincipalStep::FormComponent.new(form_model))
    end

    respond_with_turbo_streams
  end

  def create_member_call
    # The form validation worked, now is the time to invite the user
    invite_user!

    Members::CreateService
      .new(user: current_user)
      .call(
        project_id: form_model.project_id,
        user_id: form_model.id_or_email,
        role_ids: [form_model.role_id],
        notification_message: form_model.message
      )
  end

  def invite_user!
    # Invite new user by email if needed, or use existing user ID
    form_model.id_or_email = invite_new_user(form_model.id_or_email, send_notification: true)
  end

  def validation_context
    if params[:step] == "project"
      :project_step
    else
      %i[project_step principal_step]
    end
  end

  def form_model
    @form_model ||= Users::Invitation::FormModel.new(form_model_params).tap do |model|
      model.project = @project if @project && current_user.allowed_in_project?(:manage_members, @project)
    end
  end

  def set_project
    @project = Project.find(params[:project_id]) if params[:project_id].present?
  end

  def dialog_title
    I18n.t("users.invite_user_modal.type.#{form_model.principal_type.underscore}.title",
           project_name: form_model.project_name)
  end

  def form_model_params
    return {} unless params[:user_invitation]

    permitted_params.user_invitation
  end
end
