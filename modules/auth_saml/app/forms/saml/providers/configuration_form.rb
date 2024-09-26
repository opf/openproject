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
    class ConfigurationForm < BaseForm
      form do |f|
        f.text_field(
          name: :sp_entity_id,
          label: I18n.t("activemodel.attributes.saml/provider.sp_entity_id"),
          caption: I18n.t("saml.instructions.sp_entity_id"),
          disabled: provider.seeded_from_env?,
          required: true,
          input_width: :large
        )
        f.text_field(
          name: :idp_sso_service_url,
          label: I18n.t("activemodel.attributes.saml/provider.idp_sso_service_url"),
          caption: I18n.t("saml.instructions.idp_sso_service_url"),
          disabled: provider.seeded_from_env?,
          required: true,
          input_width: :large
        )
        f.text_field(
          name: :idp_slo_service_url,
          label: I18n.t("activemodel.attributes.saml/provider.idp_slo_service_url"),
          caption: I18n.t("saml.instructions.idp_slo_service_url"),
          disabled: provider.seeded_from_env?,
          required: false,
          input_width: :large
        )
        f.text_area(
          name: :idp_cert,
          rows: 10,
          label: I18n.t("activemodel.attributes.saml/provider.idp_cert"),
          caption: I18n.t("saml.instructions.idp_cert"),
          disabled: provider.seeded_from_env?,
          required: true,
          input_width: :large
        )
        f.select_list(
          name: "name_identifier_format",
          label: I18n.t("activemodel.attributes.saml/provider.name_identifier_format"),
          input_width: :large,
          disabled: provider.seeded_from_env?,
          caption: I18n.t("saml.instructions.name_identifier_format")
        ) do |list|
          Saml::Defaults::NAME_IDENTIFIER_FORMATS.each do |format|
            list.option(label: format, value: format)
          end
        end
        f.check_box(
          name: :limit_self_registration,
          label: I18n.t("activemodel.attributes.saml/provider.limit_self_registration"),
          caption: I18n.t("saml.instructions.limit_self_registration"),
          disabled: provider.seeded_from_env?,
          required: false,
          input_width: :large
        )
        f.text_field(
          name: :icon,
          label: I18n.t("activemodel.attributes.saml/provider.icon"),
          caption: I18n.t("saml.instructions.icon"),
          disabled: provider.seeded_from_env?,
          required: false,
          input_width: :large
        )
      end
    end
  end
end
