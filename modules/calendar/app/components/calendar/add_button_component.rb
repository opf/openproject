# frozen_string_literal: true

# -- copyright
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
# ++
#

module Calendar
  class AddButtonComponent < ::AddButtonComponent
    def render?
      if current_project
        User.current.allowed_in_project?(:manage_calendars, current_project)
      else
        User.current.allowed_in_any_project?(:manage_calendars)
      end
    end

    def dynamic_path
      if current_project
        new_project_calendars_path(current_project)
      else
        new_calendar_path
      end
    end

    def id
      "add-calendar-button"
    end

    def test_selector
      "add-calendar-button"
    end

    def accessibility_label_text
      I18n.t("js.calendar.create_new")
    end

    def label_text
      I18n.t(:label_calendar)
    end
  end
end
