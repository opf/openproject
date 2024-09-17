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
      class OAuthAccessGrantedModalComponent < ApplicationComponent
        include OpTurbo::Streamable

        def initialize(storage:, **)
          @storage = find_storage(storage)
          super(@storage, **)
        end

        def render?
          storage.present? && OAuthClientToken.exists?(user: User.current, oauth_client: storage.oauth_client)
        end

        private

        attr_reader :storage

        def dialog_id = "#{wrapper_key}-dialog-id"
        def dialog_body_id = "#{wrapper_key}-dialog-body-id"
        def cancel_button_text = I18n.t("button_close")

        def title
          I18n.t("storages.oauth_access_granted_modal.storage_admin.access_granted_screen_reader",
                 storage: storage.name)
        end

        def body_text
          success_title = I18n.t("storages.oauth_access_granted_modal.access_granted")
          concat(render(::Storages::OpenProjectStorageModalComponent::Body.new(:success, success_subtitle:, success_title:)))
        end

        def success_subtitle
          I18n.t("storages.oauth_access_granted_modal.storage_admin.storage_ready", storage: storage.name)
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
