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

class Projects::PhaseStatusButtonComponent < ApplicationComponent
  include ApplicationHelper
  include OpTurbo::Streamable
  include OpPrimer::ComponentHelpers
  include Primer::ClassNameHelper
  include ProjectPhaseStatusHelper

  def initialize(phase:, **system_arguments)
    super
    @status = Projects::PhaseStatuses.find(phase.status)
    @system_arguments = system_arguments
  end

  def before_render
    @system_arguments[:classes] = class_names(
      @system_arguments[:classes],
      helpers.hl_background_muted_class(:project_phase_status, @status.id)
    )
  end

  def render? = @status.present?

  private

  def build_items
    Projects::PhaseStatuses::AVAILABLE.map { build_item(it) }
  end

  def build_item(status)
    OpPrimer::StatusButtonOption.new(
      name: project_phase_status_name(status.code),
      description: project_phase_status_description(status.code),
      color_namespace: :project_status,
      color_ref: status.id,
      icon: status.icon,
      item_id: status.id,
      tag: :a,
      content_arguments: {
        data: { turbo_method: status.value ? :put : :delete },
        aria: { current: (true if status == @status) }
      }
    )
  end
end
