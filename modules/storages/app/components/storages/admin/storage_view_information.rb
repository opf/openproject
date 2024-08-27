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

module Storages::Admin
  module StorageViewInformation
    private

    def editable_storage?
      storage.persisted?
    end

    def storage_description
      [I18n.t("storages.provider_types.#{storage}.name"),
       storage.name,
       storage.host].compact.join(" - ")
    end

    def configuration_check_label
      if storage.provider_type_nextcloud?
        configuration_check_label_for(:host_name_configured)
      elsif storage.provider_type_one_drive?
        configuration_check_label_for(:name_configured, :storage_tenant_drive_configured)
      end
    end

    def configuration_check_label_for(*configs)
      # do not show the status label, if storage is completely empty (initial state)
      return if storage.configuration_checks.values.none?

      if storage.configuration_checks.slice(*configs.map(&:to_sym)).values.all?
        status_label(I18n.t(:label_completed), scheme: :success, test_selector: "label-#{configs.join('-')}-status")
      else
        status_label(I18n.t(:label_incomplete), scheme: :attention, test_selector: "label-#{configs.join('-')}-status")
      end
    end

    def status_label(label, scheme:, test_selector:)
      render(Primer::Beta::Label.new(scheme:, test_selector:)) { label }
    end

    def automatically_managed_project_folders_status_label
      # do not show the status label, if storage is completely empty (initial state)
      return if storage.configuration_checks.values.none?

      test_selector = "label-managed-project-folders-status"

      if storage.automatic_management_enabled?
        status_label(I18n.t("storages.label_active"), scheme: :success, test_selector:)
      elsif storage.automatic_management_unspecified?
        status_label(I18n.t(:label_incomplete), scheme: :attention, test_selector:)
      else
        status_label(I18n.t("storages.label_inactive"), scheme: :secondary, test_selector:)
      end
    end

    def openproject_oauth_client_description
      return unless storage.oauth_application

      "#{I18n.t('storages.label_oauth_client_id')}: #{storage.oauth_application.uid}"
    end

    def provider_oauth_client_description
      if storage.oauth_client
        "#{I18n.t('storages.label_oauth_client_id')}: #{storage.oauth_client.client_id}"
      else
        I18n.t("storages.configuration_checks.oauth_client_incomplete.#{storage}")
      end
    end

    def provider_redirect_uri_description
      if storage.oauth_client
        "#{I18n.t('storages.label_uri')}: #{storage.oauth_client.redirect_uri}"
      else
        I18n.t("storages.configuration_checks.redirect_uri_incomplete.#{storage}")
      end
    end
  end
end
