#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require 'securerandom'

module SettingsHelper
  extend self
  include OpenProject::FormTagHelper

  def system_settings_tabs
    [
      {
        name: 'general',
        controller: '/admin/settings/general_settings',
        label: :label_general
      },
      {
        name: 'languages',
        controller: '/admin/settings/languages_settings',
        label: :label_languages
      },
      {
        name: 'projects',
        controller: '/admin/settings/projects_settings',
        label: :label_project_plural
      },
      {
        name: 'repositories',
        controller: '/admin/settings/repositories_settings',
        label: :label_repository_plural
      },
      {
        name: 'experimental',
        controller: '/admin/settings/experimental_settings',
        label: :label_experimental
      }
    ]
  end

  def setting_select(setting, choices, options = {})
    if blank_text = options.delete(:blank)
      choices = [[blank_text.is_a?(Symbol) ? I18n.t(blank_text) : blank_text, '']] + choices
    end

    setting_label(setting, options) +
      wrap_field_outer(options) do
        styled_select_tag("settings[#{setting}]",
                          options_for_select(choices, Setting.send(setting).to_s),
                          disabled_setting_option(setting).merge(options))
      end
  end

  def setting_multiselect(setting, choices, options = {})
    direction = options.delete(:direction) || :vertical
    setting_label(setting, options) +
      content_tag(:span, class: "form--field-container -#{direction}") do
        hidden = with_empty_unless_writable(setting) do
          hidden_field_tag("settings[#{setting}][]", '')
        end
        multiselect_choices = choices.map do |choice|
          setting_multiselect_choice(setting, choice, options)
        end

        safe_join([hidden, *multiselect_choices])
      end
  end

  def settings_matrix(settings, choices, options = {})
    content_tag(:table, class: 'form--matrix') do
      content_tag(:thead, build_settings_matrix_head(settings, options)) +
        content_tag(:tbody, build_settings_matrix_body(settings, choices))
    end
  end

  def setting_text_field(setting, options = {})
    setting_field_wrapper(setting, options) do
      styled_text_field_tag("settings[#{setting}]",
                            Setting.send(setting),
                            disabled_setting_option(setting).merge(options))
    end
  end

  def setting_number_field(setting, options = {})
    setting_field_wrapper(setting, options) do
      styled_number_field_tag("settings[#{setting}]",
                              Setting.send(setting),
                              disabled_setting_option(setting).merge(options))
    end
  end

  def setting_time_field(setting, options = {})
    setting_field_wrapper(setting, options) do
      styled_time_field_tag("settings[#{setting}]", Setting.send(setting), options)
    end
  end

  def setting_field_wrapper(setting, options)
    unit = options.delete(:unit)
    unit_html = ''

    if unit
      unit_id = SecureRandom.uuid
      options[:'aria-describedby'] = unit_id
      unit_html = content_tag(:span,
                              unit,
                              class: 'form--field-affix',
                              'aria-hidden': true,
                              id: unit_id)
    end

    setting_label(setting, options) +
      wrap_field_outer(options) do
        yield + unit_html
      end
  end

  def setting_text_area(setting, options = {})
    setting_label(setting, options) +
      wrap_field_outer(options) do
        value = Setting.send(setting)

        if value.is_a?(Array)
          value = value.join("\n")
        end

        styled_text_area_tag("settings[#{setting}]",
                             value,
                             disabled_setting_option(setting).merge(options))
      end
  end

  def setting_check_box(setting, options = {})
    setting_label(setting, options) +
      wrap_field_outer(options) do
        hidden = with_empty_unless_writable(setting) do
          tag(:input, type: 'hidden', name: "settings[#{setting}]", value: 0, id: "settings_#{setting}_hidden")
        end

        hidden +
          styled_check_box_tag("settings[#{setting}]",
                               1,
                               Setting.send(:"#{setting}?"),
                               disabled_setting_option(setting).merge(options))
      end
  end

  def setting_password(setting, options = {})
    setting_label(setting, options) +
      wrap_field_outer(options) do
        styled_password_field_tag("settings[#{setting}]",
                                  Setting.send(setting),
                                  disabled_setting_option(setting).merge(options))
      end
  end

  def setting_label(setting, options = {})
    label = options[:label]
    return ''.html_safe if label == false

    styled_label_tag(
      "settings_#{setting}", options[:not_translated_label] || I18n.t(label || "setting_#{setting}"),
      options.slice(:title)
    )
  end

  def setting_block(setting, options = {}, &)
    setting_label(setting, options) + wrap_field_outer(options, &)
  end

  private

  def wrap_field_outer(options, &)
    if options[:label] == false
      yield
    else
      content_tag(:span, class: 'form--field-container', &)
    end
  end

  def build_settings_matrix_head(settings, options = {})
    content_tag(:tr, class: 'form--matrix-header-row') do
      content_tag(:th, I18n.t(options[:label_choices] || :label_choices),
                  class: 'form--matrix-header-cell') +
        settings.map do |setting|
          content_tag(:th, class: 'form--matrix-header-cell') do
            hidden_field_tag("settings[#{setting}][]", '') +
              I18n.t("setting_#{setting}")
          end
        end.join.html_safe
    end
  end

  def build_settings_matrix_body(settings, choices)
    choices.map do |choice|
      value = choice[:value]
      caption = choice[:caption] || value.to_s
      exceptions = Array(choice[:except]).compact
      content_tag(:tr, class: 'form--matrix-row') do
        content_tag(:td, caption, class: 'form--matrix-cell') +
          settings_matrix_tds(settings, exceptions, value)
      end
    end.join.html_safe # rubocop:disable Rails/OutputSafety
  end

  def settings_matrix_tds(settings, exceptions, value)
    settings.map do |setting|
      content_tag(:td, class: 'form--matrix-checkbox-cell') do
        unless exceptions.include?(setting)
          styled_check_box_tag("settings[#{setting}][]", value,
                               Setting.send(setting).include?(value),
                               disabled_setting_option(setting).merge(id: "#{setting}_#{value}"))
        end
      end
    end.join.html_safe # rubocop:disable Rails/OutputSafety
  end

  def setting_multiselect_choice(setting, choice, options)
    text, value, choice_options = (choice.is_a?(Array) ? choice : [choice, choice])
    choice_options = disabled_setting_option(setting)
                       .merge(choice_options || {})
                       .merge(options.except(:id))
    choice_options[:id] = "#{setting}_#{value}"

    content_tag(:label, class: 'form--label-with-check-box') do
      checked = Setting.send(setting).include?(value)
      check_box_tag = styled_check_box_tag("settings[#{setting}][]", value, checked, choice_options)

      # Adds an hidden field if the checkbox is explicitly checked and disabled
      # so the value can be submitted.
      if choice_options[:checked] && choice_options[:disabled] && writable_setting?(setting)
        hidden_checked_input = hidden_field_tag("settings[#{setting}][]", value, id: "#{choice_options[:id]}_hidden")
      end

      safe_join([check_box_tag, text, hidden_checked_input])
    end
  end

  def disabled_setting_option(setting)
    { disabled: !writable_setting?(setting) }
  end

  def with_empty_unless_writable(setting)
    if writable_setting?(setting)
      yield
    else
      ''.html_safe
    end
  end

  def writable_setting?(setting)
    Setting.send(:"#{setting}_writable?")
  end
end
