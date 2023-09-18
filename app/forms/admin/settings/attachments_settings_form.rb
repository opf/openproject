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

  def text_area(name:, **options)
    options.reverse_merge!(
      label: setting_label(name),
      value: setting_value(name),
      disabled: setting_disabled?(name)
    )
    form.text_area(name:, **options)
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

class Admin::Settings::AttachmentsSettingsForm < ApplicationForm
  form do |attachments_form|
    attachments_form = form_for_settings(attachments_form)

    attachments_form.text_field(
      name: :attachment_max_size,
      caption: 'Size in kilobytes.'
    )

    attachments_form.text_area(
      name: :attachment_whitelist,
      value: Setting.attachment_whitelist.join("\n"),
      caption: I18n.t('settings.attachments.whitelist_text_html',
                      ext_example: '*.jpg',
                      mime_example: 'image/jpeg').html_safe,
      rows: 5
    )

    attachments_form.submit
  end

  def form_for_settings(form)
    SettingsDslFormDecorator.new(form)
  end
end
