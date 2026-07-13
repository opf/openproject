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

module Settings
  module FormHelper
    # Returns a translated string for a setting name.
    #
    # The translation key is "setting_<name>". Add additional names to the key
    # to allow for translations with more context:
    # "setting_<name>_<param2>_<param3>_...".
    #
    # @param names [Array<String | Symbol>] The name(s) of the setting
    # @return [String] The translated label
    def setting_label(*names)
      I18n.t("setting_#{names.join('_')}")
    end

    # Generates an HTML-safe caption for a setting.
    #
    # The translation key is "setting_<name>_caption". If not present, it will
    # return nil.
    #
    # The translation will be marked as html_safe automatically if it ends with
    # "_html", allowing to have HTML in the caption.
    #
    # Add additional names to the key to allow for translations with more context:
    # "setting_<name>_<context>_caption_html" for instance.
    #
    # @param names [Array<Symbol>] The name(s) of the setting
    # @return [String] The translated HTML-safe caption
    def setting_caption(*names)
      ApplicationController.helpers.t("setting_#{names.join('_')}_caption_html", default: nil) ||
        I18n.t("setting_#{names.join('_')}_caption", default: nil)
    end

    # Retrieves the current value of a setting
    #
    # @param name [Symbol] The name of the setting
    # @return [Object] The value of the setting
    def setting_value(name)
      Setting[name]
    end

    # Retrieves the allowed values for a setting's definition
    #
    # @param name [Symbol] The name of the setting
    # @return [Array] The allowed values for the setting
    def setting_allowed_values(name)
      Settings::Definition[name].allowed
    end

    # Checks if a setting is disabled.
    #
    # Any non-writable setting set by environment variables will be considered
    # disabled.
    #
    # @param name [Symbol] The name of the setting
    # @return [Boolean] `true` if the setting is disabled, `false` otherwise
    def setting_disabled?(name)
      !Setting.send(:"#{name}_writable?")
    end
  end
end
