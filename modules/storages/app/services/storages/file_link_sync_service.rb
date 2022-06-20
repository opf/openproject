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

# Handle synchronization of FileLinks with external data store such as Storages
class Storages::FileLinkSyncService
  # @param user Current user
  # @param file_links An array of FileLink objects
  def initialize(user:)
    @user = user
    @service_result = ServiceResult.success(result: [])
  end

  # Synchronize the "cached" FileLinks in the database with a Nextcloud response.
  # We assume a OAuthClientToken is present, because this service is called after
  # the storage endpoint.
  # @return ServiceResult with FileLinks in the result
  def call(file_links)
    @file_links = file_links
    # Reset permissions to nil (undefined) by default.
    @file_links.each { |file_link| file_link.origin_permission = nil }

    # Group by storage_id, creating a hash { storage_id => [file_links] }
    storage_file_link_hash = @file_links.group_by(&:storage_id)

    # Iterate over storages and send the list of file_links to Nextcloud
    storage_file_link_hash.each do |storage_id, storage_file_links|
      # Get the OAuthClientToken that will authenticate us against Nextcloud
      oauth_client = OAuthClient.find_by(integration_id: storage_id)
      connection_manager = ::OAuthClients::ConnectionManager.new(user: @user, oauth_client:)
      service_result = connection_manager.get_access_token # No scope for Nextcloud...
      oauth_client_token = service_result.result

      # Return the error codes from ConnectionManager.get_access_token to calling method
      return service_result unless service_result.success

      # Get info about files. Result is either an Exception or Net::HTTPOK with body
      storage_origin_file_ids = storage_file_links.map(&:origin_id)

      tries = 2
      parsed_response = :not_authorized
      while parsed_response == :not_authorized && tries > 0
        tries -= 1
        http_response = request_files_info(oauth_client_token, storage_origin_file_ids)
        parsed_response = parse_files_info_response(http_response) # symbol for errors, Hash for 200 result

        if parsed_response == :not_authorized && tries > 0
          refresh_service_result = connection_manager.refresh_token
          unless refresh_service_result.success?
            @service_result.merge!(refresh_service_result)
            break # parsed_response is correctly :not_authorized here
          end
        end
      end

      if parsed_response.class.to_s != "Hash"
        @service_result.result += storage_file_links.each { |file_link| file_link.origin_permission = :error }
        @service_result.success = false
        break
      end

      storage_file_links.each do |file_link|
        origin_file_info_hash = parsed_response[file_link.origin_id]

        case origin_file_info_hash['statuscode']
        when 200 # Successfully found - update infos
          next if origin_file_info_hash['trashed'] # moved to trash in Nextcloud

          sync_single_file(file_link, origin_file_info_hash)
          file_link.origin_permission = :view
          @service_result.result << file_link
        when 403 # Forbidden - file from other user?
          file_link.origin_permission = :not_allowed
          @service_result.result << file_link
        when 404 # Not found - internal error?
          file_link.destroy
        else
          file_link.origin_permission = :error
          @service_result.result << file_link
        end

        # Only saves to database if some field has actually changed.
        file_link.save unless file_link.destroyed?
      end
    end

    @service_result
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
  #
  # ToDo:
  # In case of permission errors (depending on the current user) we get:
  # "24" => { "status" => "Forbidden", "statuscode" => 403 }
  # In case of completely deleted file or other errors we might also get:
  # "24" = { "status" => "Not Found", "statuscode" => 404 }
  # ToDo: What happens if nothing at all or an empty hash comes back for an origin_file_id
  def sync_single_file(file_link, origin_file_info_hash)
    file_link.origin_mime_type = origin_file_info_hash["mimetype"]
    file_link.origin_created_by_name = origin_file_info_hash["owner_name"]
    file_link.origin_name = origin_file_info_hash["name"]
    file_link.origin_created_at = Time.zone.at(origin_file_info_hash["ctime"])
    file_link.origin_updated_at = Time.zone.at(origin_file_info_hash["mtime"])

    file_link
  end

  private

  # Check the Nextcloud status of a list of files:
  # The endpoint returns "canonical" infos per file. Canonical means that the attributes are the same
  # as the owner sees them and not the current user. If it was the current user the file name could be
  # different for that user as a shared file can be renamed.
  # @param oauth_client_token A OAuth2 authentication token also carrying the host
  # @param file_ids An array of Nextcloud IDs of files to check
  # @return A HTTP response or an Exception object
  #
  # curl -H "Accept: application/json" -H "Content-Type:application/json" -H "OCS-APIRequest: true"
  # 		-u USER:PASSWD http://my.nc.org/ocs/v1.php/apps/integration_openproject/filesinfo
  # 		-X POST -d '{"fileIds":[FILE_ID_1,FILE_ID_2,...]}'
  def request_files_info(oauth_client_token, file_ids)
    host = oauth_client_token.oauth_client.integration.host
    uri = URI.parse(File.join(host, "/ocs/v1.php/apps/integration_openproject/filesinfo"))
    request = Net::HTTP::Post.new(uri)

    json_hash = { fileIds: file_ids }
    request.body = json_hash.to_json
    request['Content-Type'] = 'application/json'
    request['OCS-APIRequest'] = 'true'
    request['Accept'] = 'application/json'
    request['Authorization'] = "Bearer #{oauth_client_token.access_token}"
    # request.basic_auth 'admin', 'admin'

    # ToDo: Handle token error requiring a refresh

    req_options = {
      max_retries: 0,
      open_timeout: 5, # seconds
      read_timeout: 3 # seconds
    }

    begin
      Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    rescue StandardError => e
      e
    end
  end

  # Takes a response from querying Nextcloud file IDS (an Exception or a HTTP::Response),
  # parses the returned JSON and
  # @return array of file information or an :error symbol
  def parse_files_info_response(response)
    return :error if response.is_a? StandardError
    return :error unless response.key?('content-type') # Reply without content-type can't be valid.
    return :error if response['content-type'].split(';').first.strip.downcase != 'application/json'
    return :not_authorized if response.code == "401" # Nextcloud response if token has expired
    return :error if response.code != "200" # Interpret any other response as an error

    begin
      response_hash = JSON.parse(response.body).dig('ocs', 'data')
    rescue JSON::ParserError
      return :error
    end

    response_hash
  end
end
