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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Projects::Settings::CostTypesController < Projects::SettingsController
  menu_item :settings_time_and_costs

  before_action :find_cost_type, only: :toggle

  def index
    @cost_types = CostType.active.order(:name)
  end

  def toggle
    if @cost_type.for_all_projects?
      respond_with_status(:unprocessable_entity)
      return
    end

    mapping = CostTypesProject.find_or_initialize_by(project_id: @project.id, cost_type_id: @cost_type.id)

    if mapping.persisted?
      mapping.destroy!
    else
      mapping.save!
    end

    respond_with_status(:ok)
  end

  private

  def find_cost_type
    @cost_type = CostType.active.find(params.expect(:id))
  end

  def respond_with_status(status)
    respond_to do |format|
      format.json { render json: {}, status: }
      format.html do
        if status == :ok
          flash[:notice] = I18n.t(:notice_successful_update)
        else
          flash[:error] = I18n.t("activerecord.errors.messages.is_for_all_cannot_modify")
        end
        redirect_to project_settings_cost_types_path(@project)
      end
    end
  end
end
