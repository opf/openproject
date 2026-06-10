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

    def column_css_class(column)
      case column
      when :status
        "status -no-ellipsis"
      else
        super
      end
    end

    def name
      helpers.avatar principal, hide_name: false, size: :mini
    end

    def status
      connection_result = storage_connection_status
      case connection_result
      when :not_connected_oauth2
        warning_icon +
          content_tag(
            :span,
            I18n.t("storages.member_connection_status.not_connected",
                   link: link_to(I18n.t("link"), ensure_connection_url)).html_safe
          )
      when :not_connected_sso
        content_tag(:span, I18n.t("storages.member_connection_status.not_connected_sso"))
      when :not_connectable
        warning_icon + content_tag(:span, I18n.t("storages.member_connection_status.not_connectable"))
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
      if storage_connected?
        return :connected if can_read_files?
        return :connected_no_permissions
      end

      return :not_connected_sso if storage.authenticate_via_idp? && member.principal.provided_by_oidc?
      return :not_connected_oauth2 if storage.authenticate_via_storage?

      :not_connectable
    end

    def storage_connected?
      member.principal.remote_identities.exists?(integration: storage)
    end

    def can_read_files?
      member.principal.admin? || member.roles.any? { |role| role.has_permission?(:read_files) }
    end

    def ensure_connection_url
      oauth_clients_ensure_connection_url(
        oauth_client_id: storage.oauth_client.client_id,
        integration_id: storage.id
      )
    end

    def warning_icon
      helpers.op_icon("icon-warning -warning")
    end
  end
end
