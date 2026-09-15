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

class AutomationsController < ApplicationController
  before_action :require_admin

  guard_enterprise_feature(:custom_actions, only: %i[new create edit update]) do
    redirect_to action: :index
  end

  before_action :find_automation, only: %i[edit update destroy]
  before_action :pad_params, only: %i[create update]

  layout "admin"

  def index
    @automations = Automation.order_by_position.includes(:triggers)
  end

  def new
    @automation = Automation.new
    @automation.triggers.build(type: "Automations::Triggers::Manual")
  end

  def edit; end

  def create
    Automations::CreateService
      .new(user: current_user)
      .call(attributes: permitted_params.automation.to_h,
            &index_or_render(:new))
  end

  def update
    Automations::UpdateService
      .new(action: @automation, user: current_user)
      .call(attributes: permitted_params.automation.to_h,
            &index_or_render(:edit))
  end

  def destroy
    @automation.destroy!

    redirect_to automations_path, status: :see_other
  end

  private

  def find_automation
    @automation = Automation.find(params.expect(:id))
  end

  def index_or_render(render_action)
    ->(call) {
      call.on_success do
        redirect_to automations_path, status: :see_other
      end

      call.on_failure do
        @automation = call.result
        render action: render_action, status: :unprocessable_entity
      end
    }
  end

  def pad_params
    return if !params[:automation] || params[:automation][:move_to]

    params[:automation][:conditions] ||= {}
    params[:automation][:actions] ||= {}
  end
end
