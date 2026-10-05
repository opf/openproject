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

class WhiteboardsController < ApplicationController
  include Collaboration::SessionContext
  include OpTurbo::ComponentStream

  before_action :require_feature_flag
  before_action :find_project_by_project_id, only: %i[index create]
  before_action :find_whiteboard, except: %i[index create]
  before_action :authorize

  layout :resolve_layout

  def index
    @whiteboards = @project.whiteboards.includes(:author).order(updated_at: :desc)
  end

  def show
    return unless Setting.real_time_text_collaboration_enabled?

    setup_collaboration_context(@whiteboard)
  end

  def create
    call = Whiteboards::CreateService
      .new(user: current_user)
      .call(title: I18n.t(:label_whiteboard_new), project: @project)

    if call.success?
      redirect_to whiteboard_path(call.result)
    else
      flash[:error] = call.errors.full_messages.join(", ")
      redirect_to project_whiteboards_path(@project)
    end
  end

  def rename_dialog
    respond_with_dialog Whiteboards::RenameDialogComponent.new(@whiteboard)
  end

  def update
    call = Whiteboards::UpdateService
      .new(user: current_user, model: @whiteboard)
      .call(params.expect(whiteboard: [:title]))

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to project_whiteboards_path(@project), status: :see_other
    else
      update_via_turbo_stream(component: Whiteboards::RenameFormComponent.new(call.result), status: :unprocessable_entity)
      respond_with_turbo_streams
    end
  end

  def destroy
    Whiteboards::DeleteService
      .new(user: current_user, model: @whiteboard)
      .call

    redirect_to project_whiteboards_path(@project), status: :see_other
  end

  private

  def require_feature_flag
    render_404 unless OpenProject::FeatureDecisions.whiteboards_active?
  end

  def find_whiteboard
    @whiteboard = Whiteboard.visible.find(params.expect(:id))
    @project = @whiteboard.project
  end

  def resolve_layout
    action_name == "show" ? "whiteboards/canvas" : "base"
  end
end
