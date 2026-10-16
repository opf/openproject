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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Projects::Settings::LifeCycleStepsController < Projects::SettingsController
  include OpTurbo::ComponentStream

  before_action :load_life_cycle_definitions, only: %i[index enable_all disable_all]

  menu_item :settings_life_cycle_steps

  def index; end

  def toggle
    definition = Project::PhaseDefinition.where(id: params[:id])

    set_steps_active_status(definition, active: params["value"])
  end

  def disable_all
    set_steps_active_status(@life_cycle_definitions, active: false)

    redirect_to action: :index
  end

  def enable_all
    set_steps_active_status(@life_cycle_definitions, active: true)

    redirect_to action: :index
  end

  private

  def load_life_cycle_definitions
    @life_cycle_definitions = Project::PhaseDefinition.order(position: :asc)
  end

  def set_steps_active_status(definitions, active:)
    ::ProjectPhases::ActivationService
      .new(user: current_user, project: @project, definitions:)
      .call(active:)
  end
end
