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

module OpenIDConnect
  module Providers
    class ClientDetailsForm < BaseForm
      form do |f|
        %i[client_id client_secret].each do |attr|
          f.text_field(
            name: attr,
            label: I18n.t("activemodel.attributes.openid_connect/provider.#{attr}"),
            caption: I18n.t("openid_connect.instructions.#{attr}"),
            disabled: provider.seeded_from_env?,
            required: true,
            input_width: :large
          )
        end
        f.text_field(
          name: :post_logout_redirect_uri,
          label: I18n.t("activemodel.attributes.openid_connect/provider.post_logout_redirect_uri"),
          caption: I18n.t("openid_connect.instructions.post_logout_redirect_uri"),
          disabled: provider.seeded_from_env?,
          required: false,
          input_width: :large
        )
        f.check_box(
          name: :limit_self_registration,
          label: I18n.t("activemodel.attributes.openid_connect/provider.limit_self_registration"),
          caption: I18n.t("openid_connect.instructions.limit_self_registration"),
          disabled: provider.seeded_from_env?,
          required: true
        )
      end
    end
  end
end
