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
  class AIAssistantsController < ::ApplicationController
    before_action :require_admin
    before_action :require_feature
    before_action :find_assistant, only: %i[edit update destroy]

    menu_item :ai_assistants

    layout "admin"

    def index
      @assistants = AI::Assistant.ordered.includes(:skills)
    end

    def new
      @assistant = AI::Assistant.new(position: (AI::Assistant.maximum(:position) || 0) + 1)
    end

    def edit; end

    def create
      @assistant = AI::Assistant.new(assistant_params)

      if @assistant.save
        flash[:notice] = t(:notice_successful_create)
        redirect_to edit_admin_ai_assistant_path(@assistant)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @assistant.update(assistant_params)
        flash[:notice] = t(:notice_successful_update)
        redirect_to admin_ai_assistants_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @assistant.destroy
      flash[:notice] = t(:notice_successful_delete)
      redirect_to admin_ai_assistants_path
    end

    private

    def require_feature
      render_404 unless OpenProject::FeatureDecisions.ai_assistance_active?
    end

    def find_assistant
      @assistant = AI::Assistant.find(params[:id])
    end

    def assistant_params
      params.expect(ai_assistant: %i[name description icon model_id position active])
    end
  end
end
