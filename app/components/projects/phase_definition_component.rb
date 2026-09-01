# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
module Projects
  class PhaseDefinitionComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def phase_text
      model.name
    end

    def phase_href
      edit_admin_settings_project_phase_definition_path(model)
    end

    def gates_text
      if model.start_gate? && model.finish_gate?
        I18n.t("settings.project_phase_definitions.both_gate")
      elsif model.start_gate?
        I18n.t("settings.project_phase_definitions.start_gate")
      elsif model.finish_gate?
        I18n.t("settings.project_phase_definitions.finish_gate")
      else
        I18n.t("settings.project_phase_definitions.no_gate")
      end
    end

    def icon
      :"op-phase"
    end

    def icon_color_class
      helpers.hl_foreground_class("project_phase_definition", model.id)
    end

    def gates_text_options
      # The tag: :div is is a hack to fix the line height difference
      # caused by font_size: :small. That line height difference
      # would otherwise lead to the text being not on the same height as the icon
      { color: :muted, font_size: :small, tag: :div }.merge(options[:gates_text_options] || {})
    end

    def phase_text_options
      { font_weight: :bold }.merge(options[:phase_text_options] || {})
    end

    def edit_link?
      options[:edit_link]
    end
  end
end
