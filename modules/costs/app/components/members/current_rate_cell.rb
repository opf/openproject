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

module Members::CurrentRateCell
  include ActionView::Helpers::NumberHelper

  delegate :project, :costs_enabled?, to: :table

  def current_rate
    if show_rate?
      link_to(
        number_to_currency(rate),
        controller: "/hourly_rates",
        action: "show",
        id: member.principal,
        project_id: project
      )
    end
  end

  def column_css_class(name)
    if name == :current_rate
      "currency"
    else
      super
    end
  end

  def rate
    member.principal.current_rate(project).try(:rate) || 0.0
  end

  def show_rate?
    costs_enabled? && user? && allow_view?
  end

  def allow_view?
    table.current_user.allowed_in_project?(:view_hourly_rates, project)
  end
end
