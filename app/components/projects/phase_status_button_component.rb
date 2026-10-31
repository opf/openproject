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
  include OpPrimer::ComponentHelpers
  include Primer::ClassNameHelper

  attr_reader :phase, :user

  def initialize(phase:, user:, **system_arguments)
    super

    @phase = phase
    @user = user
    @status = Projects::PhaseStatuses.find(phase.status)
    @system_arguments = system_arguments
  end

  def render? = @status.present?

  private

  def edit_enabled?
    user.allowed_in_project?(:edit_project_phases, phase.project)
  end

  def build_items
    Projects::PhaseStatuses::AVAILABLE.map { build_item(it) }
  end

  def build_item(status)
    OpPrimer::StatusButtonOption.new(
      name: status.name,
      description: project_phase_status_description(status.code),
      color_namespace: :project_phase_status,
      color_ref: status.id,
      icon: status.icon,
      item_id: status.id,
      tag: :a,
      href: project_phase_status_path(phase, status: status.code),
      content_arguments: {
        data: { turbo_method: status.id ? :put : :delete },
        aria: { current: (true if status == @status) }
      }
    )
  end

  ##
  # @param status_code [String | Symbol | nil] Project Phase Status code
  # @return [String] the localized description.
  def project_phase_status_description(status_code)
    I18n.t(status_code, scope: "projects.phase_status.description")
  end
end
