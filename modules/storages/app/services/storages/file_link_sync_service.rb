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

  # @param file_links An array of FileLink objects
  def initialize(user:, file_links:)
    @user = user
    @file_links = file_links
  end

  # Synchronize the files on a network storage with the locally "cached" FileLinks.
  # We assume a OAuthClientToken is present, because this is called after the storage endpoint.
  # ToDo: Handle (and test! both in Spec and with a real Nextcloud) the case
  # of sync having to request a refresh token. How do we get a scope then?
  # ToDo: Produce error conditions and handle them upstream
  # @return FileLinks in ServiceResult.result
  def call
    # Reset permissions to false by default.
    @file_links.each { |file_link| file_link.origin_permission = nil }

    # Group by storage_id, creating a hash storage_id => [file_links]
    storage_file_link_hash = @file_links.group_by(&:storage_id)

    # Iterate over storages to send the list of file_links to Nextcloud for updates
    storage_file_link_hash.each do | storage_id, storage_file_links |
      # For that one storage_id get the Nextcloud connection infrastructure
      # Get the OAuthClientToken that will authenticate us against Nextcloud
      oauth_client = OAuthClient.find_by(integration_id: storage_id)
      conman = ::OAuthClients::ConnectionManager.new(user: @user, oauth_client: oauth_client)
      service_result = conman.get_access_token # Nextcloud really just ignores scope
      oauth_client_token = service_result.result

      # Return the error codes from ConnectionManager.get_access_token to calling method
      # ToDo: Check if it's OK to pass ServiceResult from get_access_token for this service
      return service_result unless service_result.success

      # Get info about files. Result is either an Exception or Net::HTTPOK with body
      storage_origin_file_ids = storage_file_links.map{ |file_link| file_link.origin_id }

      loop_count = 2
      parsed_response = :not_authorized
      while parsed_response == :not_authorized && loop_count > 0 do
        loop_count -= 1
        http_response = request_fileinfos(oauth_client_token, storage_origin_file_ids)
        parsed_response = parse_filesinfo_response(http_response) # symbol for errors, Hash for 200 result
        service_result = conman.refresh_token if parsed_response == :not_authorized && loop_count > 0
        # ToDo: Check something with service_result?
      end

      if parsed_response.class.to_s != "Hash"
        storage_file_links.each { |file_link| file_link.origin_permission = :error }
        break
      end

      # Iterate through the list of files and update the file meta-data
      files_info_data = parsed_response["ocs"]["data"]
      files_info_data.each do | origin_file_id, origin_file_info_hash |
        # ToDo: Check for Exceptions when parsing integers?
        # ToDo: Search storage_file_links for the origin_file_id instead of find_by.
        file_link = ::Storages::FileLink.find_by(origin_id: origin_file_id, storage_id: storage_id)
        sync_single_file(file_link, origin_file_info_hash)
        # ToDo: Check that the origin_file_info_hash has statuscode = 200 and perm=:view only if 200
        file_link.origin_permission = :view # ToDo: Doesn't appear in Representer
        # Save is OK, because Nectcloud answers with "canoncial" data
        file_link.save # Only saves if some field was dirty
      end
    end # End of storage_id loop....

    # ToDo: Kick out trashed items from result list
    # ToDo: Build list of returned FileLinks from lists per storage_id
    return ServiceResult.new(success: true, result: nil)
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
  #    "trashed" : false          # ToDo: How to handle "trashed" files? -> delete from array of models, check not in CollectopmRepresenter
  # }
  #
  # ToDo:
  # In case of permission errors (depending on the current user) we get:
  # "24" => {
  # 				"status" => "Forbidden",
  # 				"statuscode" => 403,
  # }
  #
  # In case of completely deleted file or other errors we might also get:
  # "24" = {
  # 			"status" => "Not Found",
  # 			"statuscode" => 404,
  # }
  #
  # ToDo: What happens if nothing at all or an empty hash comes back for an origin_file_id
  def sync_single_file(file_link, origin_file_info_hash)
    return if file_link.nil?

    if file_link.origin_mime_type != origin_file_info_hash["mimetype"]
      file_link.origin_mime_type = origin_file_info_hash["mimetype"]
    end

    if file_link.origin_created_by_name != origin_file_info_hash["owner_name"]
      file_link.origin_created_by_name = origin_file_info_hash["owner_name"]
    end

    ctime = origin_file_info_hash["ctime"].to_i
    if ctime != 0 && file_link.origin_created_at.to_i != ctime
      file_link.origin_created_at = Time.at(ctime)
    end

    mtime = origin_file_info_hash["mtime"].to_i
    if mtime != 0 && file_link.origin_updated_at.to_i != mtime
      file_link.origin_updated_at = Time.at(mtime)
    end

    # ToDo: Change origin_name based on Nextcloud name

    # ToDo: Check if trashed has "true " as boolean or string value
    if origin_file_info_hash["trashed"] = "true"
      # ToDo: Handle deleted file
    end

    return file_link # file_link.save returns true/false...
  end

  private

  # Check the Nextcloud status of a list of files:
  # @param oauth_client_token A OAuth2 authentication token also carrying the host
  # @param file_ids An array of Nextcloud IDs of files to check
  # @return A HTTP response or an Exception object
  #
  # curl -H "Accept: application/json" -H "Content-Type:application/json" -H "OCS-APIRequest: true"
  # 		-u USER:PASSWD http://my.nc.org/ocs/v1.php/apps/integration_openproject/filesinfo
  # 		-X POST -d '{"fileIds":[FILE_ID_1,FILE_ID_2,...]}'
  def request_fileinfos(oauth_client_token, file_ids)
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
  def parse_filesinfo_response(response)
    return :error if response.is_a? StandardError
    return :error if response['content-type'].split(';').first.strip.downcase != 'application/json'
    return :not_authorized if response.code == "401" # Nextcloud response if token has expired
    return :error if response.code != "200" # Interpret any other response as an error
    begin
      response_hash = JSON.parse(response.body) #.dig('ocs', 'data', 'version', 'major')
    rescue JSON::ParserError
      return :error
    end
    response_hash
  end

end
