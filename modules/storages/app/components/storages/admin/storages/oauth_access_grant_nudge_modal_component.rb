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
#

module Storages
  module Admin
    module Storages
      class OAuthAccessGrantNudgeModalComponent < ApplicationComponent
        include OpTurbo::Streamable
        include OpPrimer::ComponentHelpers

        options dialog_id: "storages--oauth-grant-nudge-modal-component",
                dialog_body_id: "storages--oauth-grant-nudge-modal-body-component"

        def initialize(storage:, **)
          @storage = find_storage(storage)
          super(@storage, **)
        end

        def render?
          @storage.present?
        end

        private

        attr_reader :storage

        def login_button_label = I18n.t("storages.oauth_grant_nudge_modal.login_button_label", provider_type:)
        def heading_text = I18n.t("storages.oauth_grant_nudge_modal.heading", provider_type:)
        def waiting_title = I18n.t("storages.oauth_grant_nudge_modal.requesting_access_to", storage: storage.name)
        def cancel_button_text = I18n.t(:button_close)
        def body_text = I18n.t("storages.oauth_grant_nudge_modal.storage_admin.description", provider_type:)
        def provider_type = I18n.t("storages.provider_types.#{storage.short_provider_type}.name")

        def login_button_aria_label
          I18n.t("storages.oauth_grant_nudge_modal.login_button_aria_label", storage: storage.name)
        end

        def confirm_button_url
          options[:confirm_button_url] ||
            url_helpers.oauth_access_grant_admin_settings_storage_project_storages_path(storage)
        end

        def find_storage(storage_record_or_id)
          return if storage_record_or_id.blank?
          return storage_record_or_id if storage_record_or_id.is_a?(::Storages::Storage)

          ::Storages::Storage.find_by(id: storage_record_or_id)
        end
      end
    end
  end
end
