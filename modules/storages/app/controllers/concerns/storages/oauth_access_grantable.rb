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

module Storages
  module OAuthAccessGrantable
    extend ActiveSupport::Concern

    def open_redirect_to_storage_authorization_with(callback_url:, storage:, callback_modal_for: :storage)
      nonce = SecureRandom.uuid
      cookies["oauth_state_#{nonce}"] = {
        value: { href: callback_url,
                 storageId: storage.id }.to_json,
        expires: 1.hour
      }

      session[:oauth_callback_flash_modal] = case callback_modal_for
                                             when :storage
                                               storage_oauth_access_granted_modal(storage:)
                                             when :project_storage
                                               project_storage_oauth_access_granted_modal(storage:)
                                             end

      redirect_to(storage.oauth_configuration.authorization_uri(state: nonce), allow_other_host: true)
    end

    def storage_oauth_access_granted?(storage:)
      OAuthClientToken.exists?(user: User.current, oauth_client: storage.oauth_client)
    end

    def project_storage_oauth_access_grant_nudge_modal(project_storage:)
      {
        type: ::Storages::ProjectStorages::OAuthAccessGrantNudgeModalComponent.name,
        parameters: { project_storage: project_storage.id }
      }
    end

    def project_storage_oauth_access_granted_modal(storage:)
      {
        type: ::Storages::ProjectStorages::OAuthAccessGrantedModalComponent.name,
        parameters: { storage: storage.id }
      }
    end

    def storage_oauth_access_granted_modal(storage:)
      {
        type: ::Storages::Admin::Storages::OAuthAccessGrantedModalComponent.name,
        parameters: { storage: storage.id }
      }
    end
  end
end
