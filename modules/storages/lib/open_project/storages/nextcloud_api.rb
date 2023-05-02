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

module OpenProject::Storages
  class NextcloudAPI
    def initialize(username:,
                   password:,
                   hostname:)
      @username = username
      @password = password
      @hostname = hostname
      @http_options = {
        cert_store: OpenSSL::X509::Store.new.tap(&:set_default_paths),
        use_ssl: true,
      }
    end

    def groups_get
      headers = {
        'Authorization' => "Basic #{Base64::encode64(@username + ':' + @password)}",
        'OCS-APIRequest' => 'true',
      }
      path = "/ocs/v1.php/cloud/groups"
      connection do |http|
        http.get(path, headers)
      end
    end

    def group_get_members(group_id)
      headers = {
        'Authorization' => "Basic #{Base64::encode64(@username + ':' + @password)}",
        'OCS-APIRequest' => 'true',
      }
      path = "/ocs/v1.php/cloud/groups/#{group_id}"
      connection do |http|
        http.get(path, headers)
      end
    end

    # user_remove_group
    def user_add_group

    end

    def folder_info(folder_path)
      body = <<~XML
        <?xml version="1.0"?>
        <d:propfind xmlns:d="DAV:"
          xmlns:oc="http://owncloud.org/ns"
          xmlns:nc="http://nextcloud.org/ns">
        <d:prop>
          <d:resourcetype />
          <nc:acl-list />
          <oc:owner-display-name />
          <oc:fileid />
        </d:prop>
        </d:propfind>
      XML
      path = "/remote.php/dav/files/#{@username}/#{folder_path}"
      headers = {
        'Depth' => '0',
        'Authorization' => "Basic #{Base64::encode64(@username + ':' + @password)}"
      }
      connection do |http|
        http.propfind(path, body , headers).body
      end
    end

    def folder_create(folder_path)
      path = "/remote.php/dav/files/#{@username}/#{folder_path}"
      headers = {
        'Authorization' => "Basic #{Base64::encode64(@username + ':' + @password)}"
      }
      connection do |http|
        http.mkcol(path, nil, headers).body
      end
    end

    def folder_acl_get(folder_path, depth = 0)
      body = <<~XML
        <?xml version="1.0"?>
        <d:propfind xmlns:d="DAV:"
          xmlns:oc="http://owncloud.org/ns"
          xmlns:nc="http://nextcloud.org/ns">
        <d:prop>
            <nc:acl-list />
        </d:prop>
        </d:propfind>
      XML
      path = "/remote.php/dav/files/#{@username}/#{folder_path}"
      headers = {
        'Depth' => depth.to_s,
        'Authorization' => "Basic #{Base64::encode64(@username + ':' + @password)}"
      }
      connection do |http|
        http.propfind(path, body , headers).body
      end
    end

    def folder_acl_set(folder_path, users_permissions)
      body = <<~XML
<d:propertyupdate xmlns:d="DAV:"
  xmlns:oc="http://owncloud.org/ns"
  xmlns:nc="http://nextcloud.org/ns"
  xmlns:ocs="http://open-collaboration-services.org/ns">
  <d:set>
    <d:prop>
      <nc:acl-list>
        <nc:acl>
          <nc:acl-mapping-type>user</nc:acl-mapping-type>
          <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
          <nc:acl-mask>31</nc:acl-mask>
          <nc:acl-permissions>31</nc:acl-permissions>
        </nc:acl>
        <nc:acl>
          <nc:acl-mapping-type>group</nc:acl-mapping-type>
          <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
          <nc:acl-mask>31</nc:acl-mask>
          <nc:acl-permissions>0</nc:acl-permissions>
        </nc:acl>
        #{prepare_permissions(users_permissions).join("/n")}
      </nc:acl-list>
    </d:prop>
  </d:set>
</d:propertyupdate>
      XML
      puts body
      path = "/remote.php/dav/files/#{@username}/#{folder_path}"
      headers = {
        'Depth' => '1',
        'Authorization' => "Basic #{Base64::encode64(@username + ':' + @password)}"
      }
      connection do |http|
        http.proppatch(path, body , headers)
      end
    end

    def prepare_permissions(users_permissions)
      acls = users_permissions.map do |i|
        permissions_map = {
          read_files: 1,
          write_files: 2,
          create_files: 4,
          share_files: 16,
          delete_files: 8
        }
        username = i[:origin_user_id]
        permissions = i[:permissions].reduce(0) do |acc, (k, v)|
          acc = acc + permissions_map[k] if v
          acc
        end
        <<~ACL
        <nc:acl>
          <nc:acl-mapping-type>user</nc:acl-mapping-type>
          <nc:acl-mapping-id>#{username}</nc:acl-mapping-id>
          <nc:acl-mask>31</nc:acl-mask>
          <nc:acl-permissions>#{permissions}</nc:acl-permissions>
        </nc:acl>
        ACL
      end
    end

    private

    def connection
      Net::HTTP.start(@hostname, nil, nil, nil, nil, nil, @http_options) do |http|
        yield(http)
      end
    end
  end
end
