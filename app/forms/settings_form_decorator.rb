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

class SettingsFormDecorator
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

  def radio_button_group(name:, values:, button_options: {}, **options)
    radio_group_options = options.reverse_merge(
      label: setting_label(name)
    )
    form.radio_button_group(
      name:,
      disabled: setting_disabled?(name),
      **radio_group_options
    ) do |radio_group|
      values.each do |value|
        radio_group.radio_button(
          **button_options.reverse_merge(
            value:,
            checked: setting_value(name) == value,
            label: setting_label(name, value),
            caption: setting_caption_html(name, value)
          )
        )
      end
    end
  end

  def submit
    form.submit(name: "submit",
                label: I18n.t("button_save"),
                scheme: :primary)
  end

  protected

  def setting_label(*names)
    I18n.t("setting_#{names.join('_')}")
  end

  def setting_caption_html(*names)
    I18n.t("setting_#{names.join('_')}_caption_html").html_safe
  end

  def setting_value(name)
    Setting[name]
  end

  def setting_disabled?(name)
    !Setting.send(:"#{name}_writable?")
  end
end
