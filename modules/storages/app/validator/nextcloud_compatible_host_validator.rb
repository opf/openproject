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
class NextcloudCompatibleHostValidator < ActiveModel::EachValidator
  MINIMAL_NEXTCLOUD_VERSION = 23

  def validate_each(contract, attribute, value)
    return unless contract.model.changed_attributes.include?(attribute)

    response = request_capabilities(value)
    error_type = check_response(response)
    if error_type
      contract.errors.add(attribute, error_type)
      Rails.logger.info(message(value, response, error_type))
    end
  end

  private

  def check_response(response)
    return :cannot_be_connected_to if response.is_a? StandardError
    return :cannot_be_connected_to unless response.is_a? Net::HTTPSuccess
    return :not_nextcloud_server unless json_response?(response)
    return :minimal_nextcloud_version_unmet unless major_version_sufficient?(response)
  end

  def message(host, response_or_exception, error_type)
    if response_or_exception.is_a?(Net::HTTPResponse)
      response = response_or_exception
    else
      exception = response_or_exception
    end

    message = "Nextcloud server invalid host=#{host.inspect} error_type=#{error_type}"
    message << " http_status=#{response.code}" if response

    case error_type
    when :cannot_be_connected_to
      message << ": exception #{exception.class}: #{exception}" if exception
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

  def request_capabilities(host)
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
    rescue StandardError => e
      e
    end
  end

  def json_response?(response)
    (
      response['content-type'].split(';').first.strip.downcase == 'application/json' \
      && read_version(response)
    )
  rescue JSON::ParserError
    false
  end

  def read_version(response)
    JSON.parse(response.body).dig('ocs', 'data', 'version', 'major')
  end
end
