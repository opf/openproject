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
  module InputMethods
    include ::SettingsHelper
    include FormHelper

    # Creates a text field input for a setting.
    #
    # The text field label is set from translating the key "setting_<name>".
    #
    # Any options passed to this method will override the default options.
    #
    # @param name [Symbol] The name of the setting
    # @param options [Hash] Additional options for the text field
    # @return [Object] The text field input
    def text_field(name:, **)
      if setting_secret?(name)
        object.text_field(**decorate_secret_options(name:, **))
      else
        object.text_field(**decorate_options_with_value(name:, **))
      end
    end

    # Creates a number input for a setting.
    #
    # The minimum and maximum are taken from the setting's allowed values if
    # they are a range.
    #
    # Any options passed to this method will override the default options.
    #
    # @param name [Symbol] The name of the setting
    # @param options [Hash] Additional options for the text field
    # @return [Object] The text field input
    def number_field(name:, **)
      text_field(name:, type: :number, **range_options(setting_allowed_values(name)), **)
    end

    # Creates a text area input for a setting.
    #
    # The text field label is set from translating the key "setting_<name>".
    #
    # Any options passed to this method will override the default options.
    #
    # @param name [Symbol] The name of the setting
    # @param options [Hash] Additional options for the text field
    # @return [Object] The text field input
    def text_area(**options)
      options = decorate_options_with_value(**options)
      options[:value] = options[:value].join("\n") if options[:value].is_a?(Array)

      object.text_area(**options)
    end

    # Creates a rich text area input for a setting.
    #
    # The rich text area label is set from translating the key "setting_<name>".
    #
    # Any options passed to this method will override the default options.
    #
    # @param name [Symbol] The name of the setting
    # @param options [Hash] Additional options for the rich text area
    # @return [Object] The rich text area input
    def rich_text_area(**)
      object.rich_text_area(**decorate_options_with_value(**))
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
    def check_box(name:, **options, &)
      options = decorate_options(name:, **options)
      options[:checked] = setting_value(name) unless options.key?(:checked)

      object.check_box(**options, &)
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
    # @param values [Hash|Array] The values for the radio buttons. Default to the
    #   setting's allowed values.
    #   If a hash is provided, it is assumed it provides a :name (to derive the labels) and a :value key.
    #   Other keys are used as arguments to the radio_button.
    # @param disabled [Boolean] Force the radio button group to be disabled when
    #  true, will be disabled if the setting is not writable when false (default)
    # @param button_options [Hash] Options for individual radio buttons
    # @param options [Hash] Additional options for the radio button group
    # @return [Object] The radio button group
    def radio_button_group(name:, values: nil, button_options: {}, **, &block)
      options = decorate_options(name:, **)

      if block
        validate_no_values(values)
        object.radio_button_group(**options, &block)
      else
        values ||= setting_allowed_values(name)
        validate_values(values, name:)
        object.radio_button_group(**options) do |group|
          build_radio_button_group_values(group, name:, values:, button_options:)
        end
      end
    end

    # Creates a check box group for a setting.
    #
    # When provided with a name:
    #
    # The check box group label is set from translating the key "setting_<name>".
    # The check box label are set from translating the key
    # "setting_<name>_<value>". The caption is set from translating the key
    # "setting_<name>_<value>_caption_html", which will be rendered as HTML, or
    # "setting_<name>_<value>_caption", or nothing if none of the above are
    # defined.
    #
    # Any options passed to this method will override the default options.
    #
    # @param name [Symbol] The name of the setting.
    # @param values [Hash|Array] The values for the check boxes. Default to the
    #   setting's allowed values.
    #   If a hash is provided, it is assumed it provides a :name (to derive the labels) and a :value key.
    #   Other keys are used as arguments to the check_box.
    # @param disabled [Boolean] Force the check box group to be disabled when
    #  true, will be disabled if the setting is not writable when false (default)
    # @param check_box_options [Hash] Options for individual check boxes
    # @param options [Hash] Additional options for the check box group
    # @return [Object] The check box group
    def check_box_group(name: nil, values: nil, check_box_options: {}, **, &block)
      return object.check_box_group(**, &block) if name.nil? # non-Array style check box group

      options = decorate_options(name:, **)

      if block
        validate_no_values(values)
        object.check_box_group(**options, &block)
      else
        values ||= setting_allowed_values(name)
        validate_values(values, name:)
        object.check_box_group(**options) do |group|
          build_check_box_group_values(group, name:, values:, check_box_options:)
        end
      end
    end

    # Creates a select list for a setting.
    #
    # The select list label is set from translating the key "setting_<name>".
    #
    # Any options passed to this method will override the default options.
    #
    # @param name [Symbol] The name of the setting
    # @param values [Hash|Array] The values for the select options. Default to the
    #   setting's allowed values.
    #   If a hash is provided, it is assumed it provides a :name (to derive the labels) and a :value key.
    #   Other keys are used as arguments to the option.
    # @param disabled [Boolean] Force the select list to be disabled when
    #  true, will be disabled if the setting is not writable when false (default)
    # @param option_options [Hash] Options for individual options
    # @param options [Hash] Additional options for the select list
    # @return [Object] The select list
    def select_list(name:, values: nil, option_options: {}, **, &block)
      options = decorate_options(name:, **)

      if block
        validate_no_values(values)
        object.select_list(**options, &block)
      else
        values ||= setting_allowed_values(name)
        validate_values(values, name:)
        object.select_list(**options) do |select_list|
          build_select_list_values(select_list, name:, values:, option_options:)
        end
      end
    end

    def multi_language_text_select(name:, current_language: I18n.locale.to_s)
      # Add select list to switch
      object.select_list(
        name: :"#{name}_lang", # Should be excluded by settings params
        input_width: :small,
        id: "lang-for-#{name}",
        class: "lang-select-switch",
        label: setting_label(name),
        caption: setting_caption(name),
        include_blank: false
      ) do |select|
        lang_options_for_select(false).each do |label, value|
          select.option(
            value:,
            label:,
            selected: value == current_language
          )
        end
      end

      object.fields_for(name) do |builder|
        MultiLangForm.new(builder, name:, current_language:)
      end
    end

    # Creates a save button to submit the form
    #
    # @return [Object] The submit button
    def submit(**options)
      options.reverse_merge!(
        name: "submit",
        label: I18n.t("button_save"),
        scheme: :primary
      )
      object.submit(**options)
    end

    private

    def range_options(allowed)
      return {} unless allowed.is_a?(Range)

      {
        min: allowed.begin,
        max: allowed.exclude_end? && allowed.end ? allowed.end - 1 : allowed.end
      }.compact
    end

    def build_radio_button_group_values(group, name:, values:, button_options:)
      Array(values).each do |value|
        args = process_value_entry(value, name:, with_caption: true)
        args[:checked] = setting_value(name) == args[:value] unless args.key?(:checked)

        group.radio_button(**args.with_defaults(button_options))
      end
    end

    def build_check_box_group_values(group, name:, values:, check_box_options:)
      Array(values).each do |value|
        args = process_value_entry(value, name:, with_caption: true)
        args[:checked] = Array(setting_value(name)).include?(args[:value]) unless args.key?(:checked)

        group.check_box(**args.with_defaults(check_box_options))
      end
    end

    def build_select_list_values(select_list, name:, values:, option_options:)
      Array(values).each do |value|
        args = process_value_entry(value, name:, with_caption: false)
        args[:selected] = setting_value(name) == args[:value] unless args.key?(:selected)

        select_list.option(**args.with_defaults(option_options))
      end
    end

    # Parses a value entry from the values array and returns a hash of arguments.
    # Supports multiple formats:
    #   - [label, value] tuple
    #   - [label, value, extra_options] tuple with additional options
    #   - Hash with :name and :value keys (name used for label/caption derivation)
    #   - Simple value (label/caption derived from setting translations)
    #
    # @param value [Array, Hash, Object] The value entry to parse
    # @param name [Symbol] The setting name for translation lookups
    # @param with_caption [Boolean] Whether to add caption
    # @return [Hash] Parsed arguments hash with :value, :label, :caption, etc.
    def process_value_entry(value, name:, with_caption:) # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
      args = case value
             in [l, v]
               { label: l, value: v }
             in [l, v, rest] if rest.is_a?(Hash)
               { label: l, value: v, **rest }
             in Hash => nvh
               h = nvh.except(:name)
               h[:label] ||= setting_label(name, nvh[:name])
               h[:caption] ||= setting_caption(name, nvh[:name]) if with_caption
               h
             else # be permissive, for now
               { value: }
             end

      args[:label] ||= setting_label(name, args[:value])
      args[:caption] ||= setting_caption(name, args[:value]) if with_caption
      args
    end

    def validate_no_values(values)
      raise ArgumentError, "Pass a block or values: keyword argument. Not both." if values
    end

    def validate_values(values, name:)
      unless values
        raise ArgumentError,
              "The definition for #{name.inspect} Setting does not specify allowed values. " \
              "You must supply a values: keyword argument."
      end
    end

    def decorate_options_with_value(name:, **options)
      options = decorate_options(name:, **options)
      options[:value] = setting_value(name) unless options.key?(:value)

      options
    end

    def decorate_secret_options(name:, **)
      decorate_options(name:, **).merge(
        type: :password,
        autocomplete: "off",
        value: setting_value(name).present? ? Settings::Definition::SECRET_PLACEHOLDER : nil
      )
    end

    def decorate_options(name:, **options)
      options[:name] = name
      options[:label] ||= setting_label(name)
      options[:disabled] = setting_disabled?(name) unless options.key?(:disabled)

      options
    end
  end
end
