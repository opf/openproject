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
class NextcloudCompatibleHostValidator < ActiveModel::EachValidator
  MINIMAL_NEXTCLOUD_VERSION = 22
  AUTHORIZATION_HEADER = "Bearer TESTBEARERTOKEN".freeze

  HTTPX_TIMEOUT_SETTINGS = { timeout: { connect_timeout: 5, read_timeout: 3 } }.freeze

  def validate_each(contract, attribute, value)
    return if contract.model.changed_attributes.exclude?(attribute)

    validate_capabilities(contract, attribute, value)
    validate_setup_completeness(contract, attribute, value) if contract.errors.empty?
  end

  private

  def validate_capabilities(contract, attribute, value)
    uri = URI.parse(File.join(value, "/ocs/v2.php/cloud/capabilities"))

    response = OpenProject.httpx
                          .with(HTTPX_TIMEOUT_SETTINGS)
                          .get(uri, headers: { "Ocs-Apirequest" => "true", "Accept" => "application/json" })
    error_type = check_capabilities_response(response)

    if error_type
      contract.errors.add(attribute, error_type)
      Rails.logger.info(message(value, response, error_type))
    end
  end

  def check_capabilities_response(response)
    return :cannot_be_connected_to if response.error.present?
    return :cannot_be_connected_to unless response.status.in? 200..299
    return :not_nextcloud_server unless read_version(response)
    return :minimal_nextcloud_version_unmet unless major_version_sufficient?(response)

    nil
  end

  # Apparently some Nextcloud installations do not use mod_rewrite. Then requesting its app root (the storage host name)
  # the response is a redirect to a URI containing 'index.php' in its path. If that is the case that installation
  # is not compatible with our integration. It is missing support for Bearer token based authorization. Apparently
  # Apache strips that part of the request header by default.
  # https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/oauth2.html
  def validate_setup_completeness(contract, attribute, value)
    uri = URI.parse(File.join(value, "index.php/apps/integration_openproject/check-config"))
    response = OpenProject.httpx
                          .with(HTTPX_TIMEOUT_SETTINGS)
                          .get(uri, headers: { "Authorization" => AUTHORIZATION_HEADER })
    error_type = check_setup_completeness_response(response)

    if error_type
      contract.errors.add(attribute, error_type)
      Rails.logger.info(message(value, response, error_type))
    end
  end

  def check_setup_completeness_response(response)
    return :cannot_be_connected_to if response.error.present?
    return :op_application_not_installed if response.status.in? 300..399
    return :cannot_be_connected_to unless response.status.in? 200..299
    return :authorization_header_missing if read_authorization_header(response) != AUTHORIZATION_HEADER

    nil
  end

  def message(host, response, error_type)
    message = "Nextcloud server invalid host=#{host.inspect} error_type=#{error_type}"
    message << " http_status=#{response.status}" if response.respond_to?(:status)

    case error_type
    when :cannot_be_connected_to
      message << ": #{response.class}: #{response}"
    when :not_nextcloud_server
      message << ": either was not valid json, or value at 'ocs/data/version/major' was not defined"
    when :minimal_nextcloud_version_unmet
      message << ": version detected is #{read_version(response).inspect}, minimum is #{MINIMAL_NEXTCLOUD_VERSION}"
    end

    message
  end

  def major_version_sufficient?(response)
    return false unless response.body

    version = read_version(response)
    return false if version.nil?
    return false if version < MINIMAL_NEXTCLOUD_VERSION

    true
  end

  def read_version(response)
    response.json.dig("ocs", "data", "version", "major")
  rescue HTTPX::Error, MultiJson::ParseError
    false
  end

  def read_authorization_header(response)
    response.json["authorization_header"]
  rescue HTTPX::Error, MultiJson::ParseError
    nil
  end
end
