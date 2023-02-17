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

# Handle synchronization of FileLinks with external data store such as Storages
class Storages::FileLinkSyncService
  FILESINFO_URL_PATH = "/ocs/v1.php/apps/integration_openproject/filesinfo".freeze

  def initialize(user:)
    @user = user
    @service_result = ServiceResult.success(result: [])
  end

  def call(file_links)
    @file_links = file_links
    storage_file_link_hash = @file_links.group_by(&:storage_id)
    storage_file_link_hash.each do |storage_id, storage_file_links|
      # Add new types of storages here. We currently only support Nextcloud
      sync_nextcloud(storage_id, storage_file_links)
    end

    @service_result
  end

  private

  # Get the OAuthClientToken that will authenticate us against Nextcloud
  def get_connection_manager(storage_id)
    oauth_client = OAuthClient.find_by(integration_id: storage_id)
    ::OAuthClients::ConnectionManager.new(user: @user, oauth_client:)
  end

  def get_oauth_client_token(connection_manager)
    access_token_service_result = connection_manager.get_access_token # No scope for Nextcloud...
    if access_token_service_result.failure?
      return nil
    end

    access_token_service_result.result
  end

  # Sync a Nextcloud storage
  def sync_nextcloud(storage_id, file_links)
    connection_manager = get_connection_manager(storage_id)
    oauth_client_token = get_oauth_client_token(connection_manager)
    if oauth_client_token.nil?
      set_error_for_file_links(file_links)
      return
    end

    nextcloud_request_result = connection_manager.request_with_token_refresh(oauth_client_token) do |token|
      response = request_files_info(token, file_links.map(&:origin_id))
      Rails.logger.debug { "Got nextcloud filesinfo response: #{response.inspect}" }
      # Parse HTTP response an return a ServiceResult with:
      #   success: result= Hash with Nextcloud filesinfo (name of endpoint) data
      #   failure: result= :error or :not_authorized
      parse_files_info_response(response)
    end
    # Pass errors from Nextcloud into service result
    @service_result.merge!(nextcloud_request_result)

    if nextcloud_request_result.failure?
      set_error_for_file_links(file_links)
      return
    end

    set_file_link_permissions(file_links, nextcloud_request_result.result)
  end

  def set_file_link_permissions(file_links, parsed_response)
    file_links.each do |file_link|
      origin_file_info_hash = parsed_response[file_link.origin_id]

      case origin_file_info_hash['statuscode']
      when 200 # Successfully found - update infos
        next if origin_file_info_hash['trashed'] # moved to trash in Nextcloud

        sync_single_file(file_link, origin_file_info_hash)
        file_link.origin_permission = :view
      when 403 # Forbidden - file from other user
        file_link.origin_permission = :not_allowed
      when 404 # Not found - permanently deleted in Nextcloud
        file_link.destroy
        next # don't save and don't add file_link to result!
      else
        file_link.origin_permission = :error
      end

      @service_result.result << file_link
      file_link.save # Only saves to database if some field has actually changed.
    end
  end

  # Write the updated information from Nextcloud to a single file
  # @param storage Storage of the file
  # @param origin_file_id Nextcloud ID of the file
  # @param origin_file_info_hash Hash with updated information from Nextcloud
  # "24" => {
  #    "id" : 24,                 # origin_file_id
  #    "ctime" : 0,               # Linux epoch file creation +overwrite
  #    "mtime" : 1655301278,      # Linux epoch file modification +overwrite
  #    "mimetype" : "application/pdf",  # +overwrite
  #    "name" : "Nextcloud Manual.pdf", # "Canonical" name, could changed by owner +overwrite
  #    "owner_id" : "admin",      # ID at Nextcloud side +overwrite
  #    "owner_name" : "admin",    # Name at Nextcloud side +overwrite
  #    "size" : 12706214,         # Not used yet in OpenProject +overwrite
  #    "status" : "OK",           # Not used yet
  #    "statuscode" : 200,        # Not used yet
  #    "trashed" : false          # Exclude trashed files from result array of FileLinks
  # }
  # In case of permission errors (depending on the current user) we get:
  # "24" => { "status" => "Forbidden", "statuscode" => 403 }
  # In case of completely deleted file or other errors we might also get:
  # "24" = { "status" => "Not Found", "statuscode" => 404 }
  # rubocop:disable Metrics/AbcSize
  def sync_single_file(file_link, origin_file_info_hash)
    file_link.origin_mime_type = origin_file_info_hash["mimetype"]
    file_link.origin_created_by_name = origin_file_info_hash["owner_name"]
    file_link.origin_last_modified_by_name = origin_file_info_hash["modifier_name"]
    file_link.origin_name = origin_file_info_hash["name"]
    file_link.origin_created_at = Time.zone.at(origin_file_info_hash["ctime"])
    file_link.origin_updated_at = Time.zone.at(origin_file_info_hash["mtime"])

    file_link
  end

  # rubocop:enable Metrics/AbcSize

  def set_error_for_file_links(storage_file_links)
    @service_result.result += storage_file_links.each { |file_link| file_link.origin_permission = :error }
    @service_result.success = false
  end

  # Check the Nextcloud status of a list of files:
  # The endpoint returns "canonical" infos per file. Canonical means that the attributes are the same
  # as the owner sees them and not the current user. If it was the current user the file name could be
  # different for that user as a shared file can be renamed.
  # @param file_ids An array of Nextcloud IDs of files to check
  # @return A HTTP response or an Exception object
  #
  # curl -H "Accept: application/json" -H "Content-Type:application/json" -H "OCS-APIRequest: true"
  # 		-u USER:PASSWD http://my.nc.org/ocs/v1.php/apps/integration_openproject/filesinfo
  # 		-X POST -d '{"fileIds":[FILE_ID_1,FILE_ID_2,...]}'
  def request_files_info(token, file_ids)
    host = token.oauth_client.integration.host
    uri = URI.parse(File.join(host, FILESINFO_URL_PATH))
    request = build_files_info_request(uri, token, file_ids)
    opts = request_file_info_options.merge({ use_ssl: uri.scheme == 'https' })

    begin
      Net::HTTP.start(uri.hostname, uri.port, opts) do |http|
        http.request(request)
      end
    rescue StandardError => e
      e
    end
  end

  # HTTP Request options: Keep the request short for the sake of the front-end
  def request_file_info_options
    {
      max_retries: 0,
      open_timeout: 5, # seconds
      read_timeout: 3 # seconds
    }
  end

  def build_files_info_request(uri, token, file_ids)
    request = Net::HTTP::Post.new(uri)
    request.body = { fileIds: file_ids }.to_json
    {
      'Content-Type': 'application/json',
      'OCS-APIRequest': 'true',
      Accept: 'application/json',
      Authorization: "Bearer #{token.access_token}"
    }.each { |header, value| request[header] = value }

    request
  end

  # Takes a response from querying Nextcloud file IDS (an Exception or a HTTP::Response),
  # parses the returned JSON and
  # @returns ServiceResult containing data in result and success=true,
  #   or success=false with result=:error or result=:not_authorized.
  def parse_files_info_response(response)
    return ServiceResult.failure(result: :error) if files_info_response_error?(response)
    return ServiceResult.failure(result: :not_authorized) if ["401", "403"].include?(response.code)
    return ServiceResult.failure(result: :error) unless response.code == "200"

    begin
      response_hash = JSON.parse(response.body).dig('ocs', 'data')
    rescue JSON::ParserError => e
      return ServiceResult.failure(result: :error)
                          .errors.add(:base, "JSON parser error: #{e.message}")
    end

    ServiceResult.success(result: response_hash)
  end

  def files_info_response_error?(response)
    response.nil? ||
      response.is_a?(StandardError) ||
      !response.key?('content-type') || # Reply without content-type can't be valid.
      response['content-type'].split(';').first.strip.downcase != 'application/json'
  end
end
