# frozen_string_literal: true

# -- copyright
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

module Storages::Storages
  class NextcloudContract < ::ModelContract
    attribute :host
    validates :host, url: { message: :invalid_host_url }, length: { maximum: 255 }
    # Check that a host actually is a storage server.
    # But only do so if the validations above for URL were successful.
    validates :host, secure_context_uri: true, nextcloud_compatible_host: true, unless: -> { errors.include?(:host) }

    attribute :automatically_managed

    attribute :username
    validates :username, presence: true, if: :nextcloud_storage_automatic_management_enabled?
    validates :username,
              absence: true,
              unless: -> { nextcloud_storage_automatic_management_enabled? || nextcloud_default_storage_username? }

    attribute :password
    validates :password, presence: true, if: :nextcloud_storage_automatic_management_enabled?
    validates :password, absence: true, unless: :nextcloud_storage_automatic_management_enabled?

    validate do
      if nextcloud_storage_automatic_management_enabled? && errors.exclude?(:host) && errors.exclude?(:password)
        NextcloudApplicationCredentialsValidator.new(self).call
      end
    end

    private

    def nextcloud_storage_automatic_management_enabled?
      return false unless nextcloud_storage?

      @model.automatic_management_enabled?
    end

    def nextcloud_default_storage_username?
      return false unless nextcloud_storage?

      @model.username == @model.provider_fields_defaults[:username]
    end

    def nextcloud_storage?
      @model.is_a?(Storages::NextcloudStorage)
    end
  end
end
