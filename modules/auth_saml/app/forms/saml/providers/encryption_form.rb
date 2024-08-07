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
    class EncryptionForm < ApplicationForm
      form do |f|
        f.check_box(
          name: :authn_requests_signed,
          label: I18n.t("activemodel.attributes.saml/provider.authn_requests_signed"),
          caption: I18n.t("saml.instructions.authn_requests_signed"),
          required: true
        )
        f.check_box(
          name: :want_assertions_signed,
          label: I18n.t("activemodel.attributes.saml/provider.want_assertions_signed"),
          caption: I18n.t("saml.instructions.want_assertions_signed"),
          required: true
        )
        f.check_box(
          name: :want_assertions_encrypted,
          label: I18n.t("activemodel.attributes.saml/provider.want_assertions_encrypted"),
          caption: I18n.t("saml.instructions.want_assertions_encrypted"),
          required: true
        )
        f.text_area(
          name: :sp_certificate,
          rows: 10,
          label: I18n.t("activemodel.attributes.saml/provider.sp_certificate"),
          caption: I18n.t("saml.instructions.sp_certificate"),
          required: false,
          input_width: :large
        )
        f.text_area(
          name: :sp_private_key,
          rows: 10,
          label: I18n.t("activemodel.attributes.saml/provider.sp_private_key"),
          caption: I18n.t("saml.instructions.sp_private_key"),
          required: false,
          input_width: :large
        )
      end

      def initialize(provider:)
        super()
        @provider = provider
      end
    end
  end
end
