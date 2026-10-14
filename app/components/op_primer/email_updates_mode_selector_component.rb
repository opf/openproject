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
  class EmailUpdatesModeSelectorComponent < ModeSelectorComponent
    def initialize(enabled:, path:, title:, enabled_description:, disabled_description:, alt_text: nil, show_button: true,
                   method: :get)
      if !show_button && alt_text.blank?
        raise ArgumentError, "alt_text must be provided when the button is shown conditionally"

      end

      @enabled = enabled
      @enabled_description = enabled_description
      @disabled_description = disabled_description
      super(title:, state:, description:, path:, button_label:, button_icon:, alt_text:, show_button:, method:,
            test_selector: "email-updates-mode-selector")
    end

    private

    def key
      @key ||= @enabled ? "enabled" : "disabled"
    end

    def button_icon
      @enabled ? :"bell-slash" : :bell
    end

    def button_label
      I18n.t("email_calendar_updates.button.#{key}")
    end

    def state
      I18n.t("email_calendar_updates.state.#{key}")
    end

    def description
      @enabled ? @enabled_description : @disabled_description
    end
  end
end
