# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class SettingsDslFormDecorator
  attr_reader :form

  def initialize(form)
    @form = form
  end

  def method_missing(method, ...)
    form.send(method, ...)
  end

  def respond_to_missing?(method, include_private = false)
    form.respond_to?(method, include_private)
  end

  def text_field(name:, **options)
    options.reverse_merge!(
      label: setting_label(name),
      value: setting_value(name),
      disabled: setting_disabled?(name)
    )
    form.text_field(name:, **options)
  end

  def check_box(name:, **options)
    options.reverse_merge!(
      label: setting_label(name),
      checked: setting_value(name),
      disabled: setting_disabled?(name)
    )
    form.check_box(name:, **options)
  end

  def heading(content:, tag: :h2, **)
    add_input(Primer::Beta::Heading.new(tag:, **)) { content }
  end

  def submit
    form.submit(name: 'submit',
                label: I18n.t('button_save'),
                scheme: :primary)
  end

  protected

  def setting_label(name)
    I18n.t("setting_#{name}")
  end

  def setting_value(name)
    Setting[name]
  end

  def setting_disabled?(name)
    !Setting.send(:"#{name}_writable?")
  end
end

class Admin::Settings::GeneralSettingsForm < ApplicationForm
  attr_reader :guessed_host

  def initialize(guessed_host:)
    super()
    @guessed_host = guessed_host
  end

  def form_for_settings(form)
    SettingsDslFormDecorator.new(form)
  end

  form do |general_form|
    general_form = form_for_settings(general_form)

    general_form.text_field(name: :app_title)
    general_form.text_field(name: :app_title, classes: 'form--text-field-container -middle')
    general_form.text_field(name: :per_page_options,
                            caption: "#{I18n.t(:text_comma_separated)}<br/>" \
                                     "#{I18n.t(:text_notice_too_many_values_are_inperformant)}".html_safe)
    general_form.text_field(name: :activity_days_default,
                            type: :number)
    general_form.text_field(name: :host_name,
                            caption: "#{I18n.t(:label_example)}: #{guessed_host}")
    general_form.check_box(name: :cache_formatted_text)
    general_form.check_box(name: :feeds_enabled)
    general_form.text_field(name: :feeds_limit)
    general_form.text_field(name: :work_packages_projects_export_limit)
    general_form.text_field(name: :file_max_size_displayed,
                            caption: 'Size in kilobytes')

    if OpenProject::Configuration.security_badge_displayed?
      general_form.check_box(name: :security_badge_displayed,
                             caption: I18n.t(:text_notice_security_badge_displayed_html,
                                             information_panel_label: I18n.t(:label_information),
                                             more_info_url: ::OpenProject::Static::Links[:security_badge_documentation][:href],
                                             information_panel_path: url_helpers.info_admin_index_path).html_safe)
    end

    general_form.field_set(heading: I18n.t(:setting_welcome_text)) do |subform|
      subform = form_for_settings(subform)

      subform.text_field(name: :welcome_title)
    end
    general_form.submit
  end
end
