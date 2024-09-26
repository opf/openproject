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

module Saml
  module Providers
    class MetadataOptionsForm < BaseForm
      form do |f|
        f.radio_button_group(
          name: "metadata",
          scope_name_to_model: false,
          disabled: provider.seeded_from_env?,
          label: I18n.t("saml.providers.label_metadata")
        ) do |radio_group|
          radio_group.radio_button(
            value: "none",
            checked: !@provider.has_metadata?,
            label: I18n.t("saml.settings.metadata_none"),
            caption: I18n.t("saml.instructions.metadata_none"),
            disabled: provider.seeded_from_env?,
            data: { "show-when-value-selected-target": "cause" }
          )

          radio_group.radio_button(
            value: "url",
            checked: @provider.metadata_url.present?,
            label: I18n.t("saml.settings.metadata_url"),
            caption: I18n.t("saml.instructions.metadata_url"),
            disabled: provider.seeded_from_env?,
            data: { "show-when-value-selected-target": "cause" }
          )

          radio_group.radio_button(
            value: "xml",
            checked: @provider.metadata_xml.present?,
            label: I18n.t("saml.settings.metadata_xml"),
            caption: I18n.t("saml.instructions.metadata_xml"),
            disabled: provider.seeded_from_env?,
            data: { "show-when-value-selected-target": "cause" }
          )
        end
      end
    end
  end
end
