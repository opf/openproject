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

class MeetingTemplatesController < ApplicationController
  before_action :load_and_authorize_in_optional_project
  before_action :require_enterprise_token,
                except: %i[index]

  include Layout
  include OpTurbo::ComponentStream
  include OpTurbo::FlashStreamHelper

  menu_item :meetings

  def index
    @templates = if @project
                   Meeting.available_onetime_templates.where(project_id: @project.id).order(:title)
                 else
                   accessible_ids = Project.allowed_to(User.current, :view_meetings).select(:id)
                   base = Meeting.available_onetime_templates
                   base.where(project_id: accessible_ids).or(base.where(sharing: :system)).order(:title)
                 end

    render "meeting_templates/index",
           locals: { menu_name: project_or_global_menu }
  end

  def new_dialog
    @template = Meeting.new(
      project: @project,
      author: User.current,
      template: true,
      recurring_meeting_id: nil
    )

    respond_with_dialog Meetings::Index::DialogComponent.new(
      meeting: @template,
      project: @project,
      template: true
    )
  end

  def create # rubocop:disable Metrics/AbcSize
    call = ::Meetings::CreateService
      .new(user: current_user)
      .call(create_template_params)

    @template = call.result

    if call.success?
      redirect_to project_meeting_path(@template.project, @template, state: :edit), status: :see_other
    elsif @project
      flash[:error] = call.errors.full_messages.join(", ")
      redirect_to action: :index, status: :unprocessable_entity
    else
      update_via_turbo_stream(
        component: Meetings::Index::FormComponent.new(
          meeting: @template,
          project: @template.project,
          template: true
        ),
        status: :bad_request
      )

      respond_with_turbo_streams
    end
  end

  private

  def require_project
    render_404 unless @project
  end

  def require_enterprise_token
    return if EnterpriseToken.allows_to?(:meeting_templates)

    respond_to do |format|
      format.turbo_stream do
        render_error_flash_message_via_turbo_stream(message: I18n.t(:notice_not_authorized))
        response.status = :forbidden
        respond_with_turbo_streams
      end
      format.any do
        request.format = "html"
        render_403
      end
    end
  end

  def create_template_params
    project_id = @project&.id || params.dig(:meeting, :project_id)
    project = project_id ? Project.find_by(id: project_id) : nil

    {
      title: I18n.t(:label_meeting_template_new),
      project:,
      template: true,
      recurring_meeting_id: nil
    }
  end
end
