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

module Admin::ScimClients
  class TokenRowComponent < OpPrimer::BorderBoxRowComponent
    def created_at
      format_date(model.created_at)
    end

    def expires_at
      if model.revoked?
        t("admin.scim_clients.token_table_component.revoked", date: format_date(model.revoked_at))
      elsif model.expired?
        t("admin.scim_clients.token_table_component.expired", date: format_date(model.expires_at))
      else
        format_date(model.expires_at)
      end
    end

    def button_links
      [revoke_button] # invisible button outside of menu
    end

    def revoke_button
      return if model.revoked? || model.expired?

      render(
        Primer::Beta::IconButton.new(
          scheme: :invisible,
          "aria-label": t("button_revoke"),
          icon: :"no-entry",
          tag: :a,
          href: deletion_dialog_admin_scim_client_static_token_path(model, scim_client_id: scim_client.id,
                                                                           target: TokenListComponent.wrapper_key),
          data: { controller: "async-dialog" },
          test_selector: "op-scim-clients--revoke-token-button"
        )
      )
    end

    private

    def scim_client
      model.application.integration
    end

    def format_date(date)
      helpers.format_date(date)
    end
  end
end
