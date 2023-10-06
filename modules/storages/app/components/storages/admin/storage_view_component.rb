# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
#
module Storages::Admin
  class StorageViewComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    alias_method :storage, :model

    private

    def storage_description
      [storage.short_provider_type.capitalize,
       storage.name,
       storage.host].compact.join(' - ')
    end

    def configuration_check_label_for(config)
      if storage.configuration_checks[config.to_sym]
        status_label(I18n.t('storages.label_connected'), scheme: :success, test_selector: "label-#{config}-status")
      else
        status_label(I18n.t('storages.label_incomplete'), scheme: :attention, test_selector: "label-#{config}-status")
      end
    end

    def automatically_managed_project_folders_status_label
      test_selector = 'label-managed-project-folders-status'

      if storage.automatically_managed?
        status_label(I18n.t('storages.label_active'), scheme: :success, test_selector:)
      elsif storage.automatic_management_unspecified?
        status_label(I18n.t('storages.label_incomplete'), scheme: :attention, test_selector:)
      else
        status_label(I18n.t('storages.label_inactive'), scheme: :secondary, test_selector:)
      end
    end

    def openproject_oauth_client?
      storage.oauth_application.present?
    end

    def provider_oauth_client?
      storage.oauth_client.present?
    end

    def openproject_oauth_client_description
      return unless storage.oauth_application

      "#{I18n.t('storages.label_oauth_client_id')}: #{storage.oauth_application.uid}"
    end

    def provider_oauth_client_description
      if storage.oauth_client
        "#{I18n.t('storages.label_oauth_client_id')}: #{storage.oauth_client.client_id}"
      else
        I18n.t('storages.configuration_checks.oauth_client_incomplete', provider: storage.short_provider_type.capitalize)
      end
    end

    def status_label(label, scheme:, test_selector:)
      render(Primer::Beta::Label.new(scheme:, data: { 'test-selector': test_selector })) { label }
    end
  end
end
