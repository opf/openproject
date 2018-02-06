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

class CustomActionsController < ApplicationController
  before_action :require_admin

  self._model_object = CustomAction
  before_action :find_model_object, only: %i(edit update destroy)

  layout 'admin'

  helper_method :gon

  def index
    @custom_actions = CustomAction.order_by_name
  end

  def new
    @custom_action = CustomAction.new
  end

  def create
    CustomActions::CreateService
      .new(user: current_user)
      .call(attributes: permitted_params.custom_action.to_h,
            &index_or_render(:new))
  end

  def edit; end

  def update
    CustomActions::UpdateService
      .new(action: @custom_action, user: current_user)
      .call(attributes: permitted_params.custom_action.to_h,
            &index_or_render(:edit))
  end

  def destroy
    @custom_action.destroy

    redirect_to custom_actions_path
  end

  private

  def index_or_render(render_action)
    ->(call) {
      call.on_success do
        redirect_to custom_actions_path
      end

      call.on_failure do
        @custom_action = call.result
        @errors = call.errors
        render action: render_action
      end
    }
  end
end
