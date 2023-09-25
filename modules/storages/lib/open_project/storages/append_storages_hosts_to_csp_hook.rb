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

class ::OpenProject::Storages::AppendStoragesHostsToCspHook < OpenProject::Hook::Listener
  # OpenProject's front-end needs to allow the browser to connect to external
  # file servers for direct file uploads. Therefore it needs to extend its
  # Content Security Policy (CSP) `connect-src` with the hostnames of all
  # servers that the current user is allowed to upload files to. That is all
  # storages activated in at least one active project for which the user has the
  # `manage_file_links` permission.
  #
  # The allowed values can be different for each user and can change on store
  # activations, store removals, role changes, and even project membership
  # changes. Caching it without accessing the database seems almost impossible,
  # so we decided to not do it for now.
  #
  # The CSP is extended for all HTML requests as work packages can pop in many
  # places of OpenProject, and we want to be able to upload in all those places
  # (work packages module, BCF module, notification center, boards, ...).
  def application_controller_before_action(context)
    controller = context[:controller]

    active_nextcloud_storages_hosts = ::Storages::NextcloudStorage
                                        .where(id: ::Storages::ProjectStorage.select(:storage_id))
                                        .pluck(:host)
                                        .map(&method(:remove_uri_path))

    if active_nextcloud_storages_hosts.present?
      controller.append_content_security_policy_directives(
        frame_ancestors: active_nextcloud_storages_hosts
      )
    end

    storage_ids = ::Storages::ProjectStorage.where(
      project_id: Project.allowed_to(User.current, :manage_file_links)
    ).select(:storage_id)
    storages_hosts = ::Storages::Storage
                       .where(id: storage_ids)
                       .where.not(host: nil)
                       .pluck(:host)
                       .map(&method(:remove_uri_path))

    if storages_hosts.present?
      # secure_headers gem provides this helper method to append to the current content security policy
      controller.append_content_security_policy_directives(connect_src: storages_hosts)
    end
  end

  private

  def remove_uri_path(url)
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.host}"
  end
end
