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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class TwoFactorAuthentication::Devices::WebauthnDeviceForm < ApplicationForm
  def initialize(index_path:)
    super()
    @index_path = index_path
  end

  form do |f|
    f.fieldset_group(title: model.name,
                     description: helpers.t("two_factor_authentication.devices.webauthn.further_steps")) do |fg|
      fg.text_field(
        name: :identifier,
        label: attribute_name(:identifier),
        required: true,
        caption: helpers.t("two_factor_authentication.devices.text_identifier")
      )
    end

    f.html_content do
      helpers.hidden_field_tag(
        "device[webauthn_credential]",
        "",
        "data-two-factor-authentication-target": "webauthnCredential"
      )
    end

    f.html_content do
      helpers.content_tag(:div, "",
                          class: "form--field-error",
                          data: { "two-factor-authentication-target": "errorDisplay" })
    end

    f.group(layout: :horizontal) do |button_group|
      button_group.button(name: :cancel,
                          tag: :a,
                          label: helpers.t(:button_cancel),
                          scheme: :default,
                          href: @index_path) do |button|
        button.with_leading_visual_icon(icon: :x)
        helpers.t(:button_cancel)
      end
      button_group.submit(name: :continue, label: I18n.t(:button_continue), scheme: :primary) do |button|
        button.with_leading_visual_icon(icon: :check)
        helpers.t(:button_continue)
      end
    end
  end
end
