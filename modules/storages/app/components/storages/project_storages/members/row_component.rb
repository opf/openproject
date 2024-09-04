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

module Storages::ProjectStorages::Members
  class RowComponent < ::RowComponent
    property :principal,
             :created_at

    def member
      row
    end

    def row_css_id
      "member-#{member.principal.id}"
    end

    def row_css_class
      "member #{principal_class_name}".strip
    end

    def name
      helpers.avatar principal, hide_name: false, size: :mini
    end

    def status
      connection_result = storage_connection_status

      if connection_result == :not_connected
        ensure_connection_url = oauth_clients_ensure_connection_url(
          oauth_client_id: storage.oauth_client.client_id,
          storage_id: storage.id
        )
        helpers.op_icon("icon-warning -warning") +
          content_tag(
            :span,
            I18n.t("storages.member_connection_status.not_connected",
                   link: link_to(I18n.t("link"), ensure_connection_url),
                   class: "pl-2").html_safe
          )
      else
        I18n.t("storages.member_connection_status.#{connection_result}")
      end
    end

    private

    delegate :storage, to: :table

    def principal_class_name
      principal.model_name.singular
    end

    def principal_show_path
      case principal
      when User
        user_path(principal)
      when Group
        show_group_path(principal)
      else
        placeholder_user_path(principal)
      end
    end

    def storage_connection_status
      return :not_connected unless oauth_client_connected?

      if can_read_files?
        :connected
      else
        :connected_no_permissions
      end
    end

    def oauth_client_connected?
      storage.oauth_client.present? &&
        member.principal.remote_identities.exists?(oauth_client: storage.oauth_client)
    end

    def can_read_files?
      member.principal.admin? || member.roles.any? { |role| role.has_permission?(:read_files) }
    end
  end
end
