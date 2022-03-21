#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
    MINIMAL_NEXTCLOUD_VERSION = 23

    include ::Storages::Storages::Concerns::ManageStoragesGuarded
    include ActiveModel::Validations

    attribute :name
    validates :name, presence: true, length: { maximum: 255 }

    attribute :provider_type
    validates :provider_type, inclusion: { in: ->(*) { Storages::Storage::PROVIDER_TYPES } }

    attribute :creator, writable: false

    attribute :host
    validates :host, url: true, length: { maximum: 255 }

    # Check that a host actually is a storage server.
    # But only do so if the validations above for URL were successful.
    validate :validate_host_reachable, unless: -> { errors.include?(:host) }

    def validate_host_reachable
      return unless model.host_changed?

      response = request_capabilities

      unless response.is_a? Net::HTTPSuccess
        errors.add(:host, :cannot_be_connected_to)
        return
      end

      unless json_response?(response)
        errors.add(:host, :not_nextcloud_server)
        return
      end

      unless major_version_sufficient?(response)
        errors.add(:host, :minimal_nextcloud_version_unmet)
      end
    end

    def major_version_sufficient?(response)
      return false unless response.body

      version = JSON.parse(response.body).dig('ocs', 'data', 'version', 'major')
      return false if version.nil?
      return false if version < MINIMAL_NEXTCLOUD_VERSION

      true
    end

    private

    def request_capabilities
      uri = URI.parse(File.join(host, '/ocs/v2.php/cloud/capabilities'))
      request = Net::HTTP::Get.new(uri)
      request["Ocs-Apirequest"] = "true"
      request["Accept"] = "application/json"

      req_options = {
        max_retries: 0,
        open_timeout: 5, # seconds
        read_timeout: 3, # seconds
        use_ssl: uri.scheme == "https"
      }

      begin
        Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
      rescue StandardError
        :unreachable
      end
    end

    def json_response?(response)
      (
        response['content-type'].split(';').first.strip.downcase == 'application/json' \
        && JSON.parse(response.body).dig('ocs', 'data', 'version', 'major')
      )
    rescue JSON::ParserError
      false
    end
  end
end
