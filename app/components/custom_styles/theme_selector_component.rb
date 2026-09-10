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

module CustomStyles
  class ThemeSelectorComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    attr_reader :theme_options, :current_theme, :selected_tab_name

    def initialize(theme_options:, current_theme:, selected_tab_name:)
      super()

      @theme_options = theme_options
      @current_theme = current_theme
      @selected_tab_name = selected_tab_name
    end

    private

    def form_arguments
      {
        url: url_helpers.update_design_themes_path(tab: selected_tab_name),
        method: :post,
        data: {
          controller: "auto-submit",
          turbo_confirm: (I18n.t("admin.custom_styles.theme_warning") if current_theme.blank?)
        }
      }
    end

    def select_arguments
      {
        name: :theme,
        label: I18n.t("admin.custom_styles.color_theme"),
        caption: I18n.t("admin.custom_styles.color_theme_caption"),
        input_width: :medium,
        scope_name_to_model: false,
        data: {
          action: "auto-submit#submit",
          test_selector: "color-theme-select"
        }
      }
    end
  end
end
