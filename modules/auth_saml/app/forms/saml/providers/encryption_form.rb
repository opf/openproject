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
    class EncryptionForm < BaseForm
      form do |f|
        f.check_box(
          name: :authn_requests_signed,
          label: I18n.t("activemodel.attributes.saml/provider.authn_requests_signed"),
          caption: I18n.t("saml.instructions.authn_requests_signed"),
          disabled: provider.seeded_from_env?,
          required: true
        )
        f.check_box(
          name: :want_assertions_signed,
          label: I18n.t("activemodel.attributes.saml/provider.want_assertions_signed"),
          caption: I18n.t("saml.instructions.want_assertions_signed"),
          disabled: provider.seeded_from_env?,
          required: true
        )
        f.check_box(
          name: :want_assertions_encrypted,
          label: I18n.t("activemodel.attributes.saml/provider.want_assertions_encrypted"),
          caption: I18n.t("saml.instructions.want_assertions_encrypted"),
          disabled: provider.seeded_from_env?,
          required: true
        )
        f.text_area(
          name: :certificate,
          rows: 10,
          label: I18n.t("activemodel.attributes.saml/provider.certificate"),
          caption: I18n.t("saml.instructions.certificate"),
          required: false,
          disabled: provider.seeded_from_env?,
          input_width: :large
        )
        f.text_area(
          name: :private_key,
          rows: 10,
          label: I18n.t("activemodel.attributes.saml/provider.private_key"),
          caption: I18n.t("saml.instructions.private_key"),
          required: false,
          disabled: provider.seeded_from_env?,
          input_width: :large
        )
        f.select_list(
          name: :digest_method,
          label: I18n.t("activemodel.attributes.saml/provider.digest_method"),
          input_width: :large,
          disabled: provider.seeded_from_env?,
          caption: I18n.t("saml.instructions.digest_method", default_option: "SHA-1")
        ) do |list|
          Saml::Defaults::DIGEST_METHODS.each do |label, value|
            list.option(label:, value:)
          end
        end
        f.select_list(
          name: :signature_method,
          label: I18n.t("activemodel.attributes.saml/provider.signature_method"),
          input_width: :large,
          disabled: provider.seeded_from_env?,
          caption: I18n.t("saml.instructions.signature_method", default_option: "RSA SHA-1")
        ) do |list|
          Saml::Defaults::SIGNATURE_METHODS.each do |label, value|
            list.option(label:, value:)
          end
        end
      end
    end
  end
end
