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

require 'net/http'
require 'uri'

# Purpose: common functionalities shared by CreateContract and UpdateContract
# UpdateService by default checks if UpdateContract exists
# and uses the contract to validate the model under consideration
# (normally it's a model).
module Storages::Storages
  class BaseContract < ::ModelContract
    MINIMAL_NEXTCLOUD_VERSION = 22

    include ::Storages::Storages::Concerns::ManageStoragesGuarded
    include ActiveModel::Validations

    attribute :name
    validates :name, presence: true, length: { maximum: 255 }

    attribute :provider_type
    validates :provider_type, inclusion: { in: ->(*) { Storages::Storage::PROVIDER_TYPES } }

    attribute :host
    validates :host, url: { message: I18n.t('activerecord.errors.messages.invalid_url') }, length: { maximum: 255 }
    # Check that a host actually is a storage server.
    # But only do so if the validations above for URL were successful.
    validates :host, secure_context_uri: true, nextcloud_compatible_host: true, unless: -> { errors.include?(:host) }
  end
end
