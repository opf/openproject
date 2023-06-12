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

class Storages::GroupFolderPropertiesSyncService
  using ::Storages::Peripherals::ServiceResultRefinements

  PERMISSIONS_MAP = {
    read_files: 1,
    write_files: 2,
    create_files: 4,
    delete_files: 8,
    share_files: 16
  }.freeze
  ALL_PERMISSIONS = PERMISSIONS_MAP.values.sum
  NO_PERMISSIONS = 0

  def initialize(storage)
    @storage = storage
    @nextcloud_system_user = storage.username
    @group = storage.group
    @group_folder = storage.group_folder
    @requests = Storages::Peripherals::StorageRequests.new(storage:)
  end

  # rubocop:disable Metrics/AbcSize
  def call
    # we have to flush state to be able to reuse the instace of the class
    @nextcloud_usernames_used_in_openproject = Set.new
    @project_folder_ids_used_in_openproject = Set.new
    @file_ids = nil
    @folders_properties = nil
    @group_users = nil

    set_group_folder_root_permissions

    @storage.projects_storages
      .automatic
      .includes(project: %i[users enabled_modules])
      .each do |project_storage|
      project = project_storage.project
      project_folder_path = project_folder_path(project)
      @project_folder_ids_used_in_openproject << ensure_project_folder(project_storage:, project_folder_path:)

      set_project_folder_permissions(path: project_folder_path, project:)
    end

    add_active_users_to_group
    remove_inactive_users_from_group
    hide_inactive_project_folders
  end
  # rubocop:enable Metrics/AbcSize

  private

  def set_group_folder_root_permissions
    permissions = {
      users: { @nextcloud_system_user.to_sym => ALL_PERMISSIONS },
      groups: { @group.to_sym => PERMISSIONS_MAP[:read_files] }
    }
    @requests
      .set_permissions_command
      .call(path: @group_folder, permissions:)
      .on_failure do |r|
      raise "set_permissions_command(path: #{@group_folder}, permissions: #{permissions}) failed: #{r.inspect}"
    end
  end

  def project_folder_path(project)
    "#{@group_folder}/#{project.name.gsub('/', '|')} (#{project.id})/"
  end

  # rubocop:disable Metrics/AbcSize
  def ensure_project_folder(project_storage:, project_folder_path:)
    project_folder_id = project_storage.project_folder_id
    project_storage.project

    if project_folder_id.present? && file_ids.include?(project_folder_id)
      source = folders_properties.find { |_k, v| v['fileid'] == project_folder_id }.first
      rename_folder(source:, target: project_folder_path) if source != project_folder_path
    else
      create_folder(path: project_folder_path, project_storage:) >> obtain_file_id >> save_file_id
    end
    # local variable is not used due to possible update_columns call
    # then the value inside the local variable will not be updated
    project_storage.project_folder_id
  end
  # rubocop:enable Metrics/AbcSize

  def file_ids
    @file_ids ||= folders_properties.map { |_path, props| props['fileid'] }
  end

  def folders_properties
    @folders_properties ||= @requests
                              .propfind_query
                              .call(depth: '1', path: @group_folder, props: %w[oc:fileid])
                              .on_failure do |r|
      raise "propfind_query(depth: 1, path: #{@group_folder}, props: #{%w[oc:fileid]}) failed: #{r.inspect}"
    end.result
  end

  def rename_folder(source:, target:)
    @requests.rename_file_command.call(source:, target:).on_failure do |r|
      raise "rename_file_command failed(source: #{source} target: #{target}) failed: #{r.inspect}"
    end
  end

  def create_folder(path:, project_storage:)
    @requests.create_folder_command.call(folder_path: path)
      .match(
        on_success: ->(_) { ServiceResult.success(result: [project_storage, path]) },
        on_failure: ->(r) { raise "create_folder_command(folder_path: #{path}) failed: #{r.inspect}, " }
      )
  end

  def save_file_id
    ->((project_storage, file_id)) do
      project_storage.update_columns(project_folder_id: file_id, updated_at: Time.current)
    end
  end

  def obtain_file_id
    ->((project_storage, path)) do
      @requests
        .propfind_query
        .call(depth: '0', path:, props: %w[oc:fileid])
        .match(
          on_success: ->(result) { ServiceResult.success(result: [project_storage, result.dig(path, 'fileid')]) },
          on_failure: ->(_result) { raise "propfind_query failed: #{r}, depth: 0, path: #{path}" }
        )
    end
  end

  def calculate_permissions(user:, project:)
    {
      read_files: user.allowed_to?(:read_files, project),
      write_files: user.allowed_to?(:write_files, project),
      create_files: user.allowed_to?(:create_files, project),
      share_files: user.allowed_to?(:share_files, project),
      delete_files: user.allowed_to?(:delete_files, project)
    }.reduce(0) do |permissions_sum, (permission, allowed)|
      if allowed
        permissions_sum + PERMISSIONS_MAP[permission]
      else
        permissions_sum
      end
    end
  end

  def set_project_folder_permissions(path:, project:)
    permissions = project_folder_permissions(project:)
    @requests.set_permissions_command.call(path:, permissions:).on_failure do |r|
      raise "set_permissions_command path(#{path}, permissions: #{permissions}) failed: #{r.inspect}"
    end
  end

  def group_users
    @group_users ||= @requests.group_users_query.call(group: @group).on_failure do |r|
      raise "group_users_query(group: #{@group}) failed: #{r.inspect}"
    end.result
  end

  def project_folder_permissions(project:)
    OAuthClientToken
      .where(oauth_client: @storage.oauth_client, users: project.users)
      .includes(:user)
      .each_with_object({
                          users: { "#{@nextcloud_system_user}": ALL_PERMISSIONS },
                          groups: { "#{@group}": NO_PERMISSIONS }
                        }) do |token, permissions|
      nextcloud_username = token.origin_user_id
      permissions[:users][nextcloud_username.to_sym] = calculate_permissions(user: token.user, project:)
      @nextcloud_usernames_used_in_openproject << nextcloud_username
    end
  end

  def add_active_users_to_group
    @nextcloud_usernames_used_in_openproject.each do |nextcloud_username|
      if group_users.exclude?(nextcloud_username)
        @requests.add_user_to_group_command.call(user: nextcloud_username).on_failure do |r|
          raise "add_user_to_group_command(user: #{netcloud_username}) failed: #{r.inspect}, "
        end
      end
    end
  end

  def remove_inactive_users_from_group
    (group_users - @nextcloud_usernames_used_in_openproject.to_a - [@nextcloud_system_user]).each do |user|
      remove_user_from_group(user)
    end
  end

  def remove_user_from_group(user)
    @requests
      .remove_user_from_group_command
      .call(user:)
      .on_failure { |r| raise "remove_user_from_group_command(user: #{user}) failed: #{r.inspect}" }
  end

  def hide_inactive_project_folders
    inactive_project_folder_paths.each { |folder| hide_folder(folder) }
  end

  def inactive_project_folder_paths
    folders_properties.except("#{@group_folder}/").each_with_object([]) do |(path, attrs), paths|
      paths.push(path) if @project_folder_ids_used_in_openproject.exclude?(attrs['fileid'])
    end
  end

  def hide_folder(path)
    permissions = {
      users: { "#{@nextcloud_system_user}": ALL_PERMISSIONS },
      groups: { "#{@group}": NO_PERMISSIONS }
    }
    @requests
      .set_permissions_command
      .call(path:, permissions:)
      .on_failure { |r| raise "set_permissions_command(path: #{path}, permissions: #{permissions}) failed: #{r.inspect}" }
  end
end
