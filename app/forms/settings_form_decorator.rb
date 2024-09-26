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

# Decorates a form object to provide a more convenient interface for
# rendering settings.
#
# It automatically sets the label, value, and disabled properties from the
# setting name and its definition attributes.
class SettingsFormDecorator
  attr_reader :form

  # Initializes a new SettingsFormDecorator
  #
  # @param form [Object] The form object to be decorated
  def initialize(form)
    @form = form
  end

  def method_missing(method, ...)
    form.send(method, ...)
  end

  def respond_to_missing?(method, include_private = false)
    form.respond_to?(method, include_private)
  end

  # Creates a text field input for a setting.
  #
  # The text field label is set from translating the key "setting_<name>".
  #
  # Any options passed to this method will override the default options.
  #
  # @param name [Symbol] The name of the setting
  # @param options [Hash] Additional options for the text field
  # @return [Object] The text field input
  def text_field(name:, **options)
    options.reverse_merge!(
      label: setting_label(name),
      value: setting_value(name),
      disabled: setting_disabled?(name)
    )
    form.text_field(name:, **options)
  end

  # Creates a check box input for a setting.
  #
  # The check box label is set from translating the key "setting_<name>".
  #
  # Any options passed to this method will override the default options.
  #
  # @param name [Symbol] The name of the setting
  # @param options [Hash] Additional options for the check box
  # @return [Object] The check box input
  def check_box(name:, **options)
    options.reverse_merge!(
      label: setting_label(name),
      checked: setting_value(name),
      disabled: setting_disabled?(name)
    )
    form.check_box(name:, **options)
  end

  # Creates a radio button group for a setting.
  #
  # The radio button group label is set from translating the key
  # "setting_<name>". The radio button label are set from translating the
  # key "setting_<name>_<value>". The caption is set from translating the
  # key "setting_<name>_<value>_caption_html", which will be rendered as HTML,
  # or "setting_<name>_<value>_caption", or nothing if none of the above
  # are defined.
  #
  # Any options passed to this method will override the default options.
  #
  # @param name [Symbol] The name of the setting
  # @param values [Array] The values for the radio buttons. Default to the
  #   setting's allowed values.
  # @param disabled [Boolean] Force the radio button group to be disabled when
  #  true, will be disabled if the setting is not writable when false (default)
  # @param button_options [Hash] Options for individual radio buttons
  # @param options [Hash] Additional options for the radio button group
  # @return [Object] The radio button group
  def radio_button_group(name:, values: [], disabled: false, button_options: {}, **options)
    values = values.presence || setting_allowed_values(name)
    radio_group_options = options.reverse_merge(
      label: setting_label(name),
      disabled: disabled || setting_disabled?(name)
    )
    form.radio_button_group(
      name:,
      **radio_group_options
    ) do |radio_group|
      values.each do |value|
        radio_group.radio_button(
          **button_options.reverse_merge(
            value:,
            checked: setting_value(name) == value,
            autocomplete: "off",
            label: setting_label(name, value),
            caption: setting_caption(name, value)
          )
        )
      end
    end
  end

  # Creates a save button to submit the form
  #
  # @return [Object] The submit button
  def submit
    form.submit(name: "submit",
                label: I18n.t("button_save"),
                scheme: :primary)
  end

  protected

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
    I18n.t("setting_#{names.join('_')}_caption_html", default: nil)&.html_safe \
      || I18n.t("setting_#{names.join('_')}_caption", default: nil)
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
