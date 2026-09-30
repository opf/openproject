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

module OpenIDConnect
  module Providers
    class MetadataDetailsForm < BaseForm
      form do |f|
        OpenIDConnect::Provider::DISCOVERABLE_STRING_ATTRIBUTES_ALL.each do |attr|
          f.text_field(
            name: attr,
            label: OpenIDConnect::Provider.human_attribute_name(attr),
            disabled: provider.seeded_from_env?,
            required: OpenIDConnect::Provider::DISCOVERABLE_STRING_ATTRIBUTES_MANDATORY.include?(attr),
            input_width: :large
          )
        end

        f.text_field(
          name: :grant_types_supported,
          label: OpenIDConnect::Provider.human_attribute_name(:grant_types_supported),
          disabled: provider.seeded_from_env?,
          required: false,
          input_width: :large
        )

        f.text_field(
          name: :icon,
          label: OpenIDConnect::Provider.human_attribute_name(:icon),
          caption: I18n.t("saml.instructions.icon"),
          disabled: provider.seeded_from_env?,
          required: false,
          input_width: :large
        )
      end
    end
  end
end
