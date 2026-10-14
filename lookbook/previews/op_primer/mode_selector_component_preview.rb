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

module OpPrimer
  class ModeSelectorComponentPreview < Lookbook::Preview
    def manual
      render_mode("manual")
    end

    def vote_based
      render_mode("vote_based")
    end

    def read_only
      render_mode("vote_based", show_button: false)
    end

    private

    def render_mode(mode, show_button: true)
      render ModeSelectorComponent.new(
        title: I18n.t("meeting.agenda_sorting.title"),
        state: I18n.t("meeting.agenda_sorting.#{mode}"),
        description: I18n.t("meeting.agenda_sorting.#{mode}_description"),
        path: "#",
        button_label: I18n.t("meeting.agenda_sorting.change"),
        button_icon: :"sort-desc",
        show_button:
      )
    end
  end
end
