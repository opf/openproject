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

class Projects::StatusBadgeComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include Primer::ClassNameHelper

  def initialize(project:, **system_arguments)
    super

    @project = project
    @status = find_status(project.status_code)
    @system_arguments = system_arguments
  end

  def before_render
    return unless @status

    @system_arguments[:classes] = class_names(
      @system_arguments[:classes],
      helpers.hl_background_class(:project_status, @status.id)
    )
  end

  def render?
    @status.present?
  end

  def name
    helpers.project_status_name(@project.status_code)
  end

  def find_status(code)
    Projects::Statuses::VALID.find { it.code&.to_s == code }
  end
end
