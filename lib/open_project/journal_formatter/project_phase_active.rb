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

class OpenProject::JournalFormatter::ProjectPhaseActive < JournalFormatter::Base
  def render(key, values, options = { html: true })
    return if !values[0] == !values[1]

    step = Project::Phase.find_by(id: key[/\d+/])
    return unless step

    name = step.definition.name
    label = options[:html] ? content_tag(:strong, name) : name

    "#{label} #{activation_message(values:)}"
  end

  private

  def activation_message(values:)
    if values[1]
      I18n.t("activity.project_phase.activated")
    elsif values[0]
      I18n.t("activity.project_phase.deactivated")
    end
  end
end
