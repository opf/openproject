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

class ManageNextcloudIntegrationJob < Cron::CronJob
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

  queue_with_priority :low

  self.cron_expression = '*/5 * * * *'

  def perform
    Storages::NextcloudStorage
      .where("provider_fields->>'has_managed_project_folders' = 'true'")
      .includes(:oauth_client)
      .each do |storage|
      NextcloudStorageManager.new(storage).call
    end
  end

  class NextcloudStorageManager
    def initialize(storage)
      @storage = storage
      @nextcloud_system_user = storage.username
      @group = storage.group
      @groupfolder = storage.groupfolder
      @nextcloud_usernames_used_in_openproject = Set.new
      @project_folder_ids_used_in_openproject = Set.new
      @requests = Storages::Peripherals::StorageRequests.new(storage:)
    end

    def call
      set_groupfolder_permissions

      @storage.projects_storages
              .where(project_folder_mode: 'automatic')
              .includes(project: %i[users enabled_modules])
              .each do |project_storage|
        handle_project_folder(project_storage:)
      end

      (group_users - @nextcloud_usernames_used_in_openproject.to_a).each do |user|
        remove_user_from_group(user)
      end

      inactive_project_folder_paths.each { |folder| hide_folder(folder) }
    end

    private

    def set_groupfolder_permissions
      permissions = {
        users: { @nextcloud_system_user.to_sym => ALL_PERMISSIONS },
        groups: { @group.to_sym => PERMISSIONS_MAP[:read_files] }
      }
      @requests
        .set_permissions_command
        .call(path: @groupfolder, permissions:)
        .on_failure { |r| raise "set_permissions_command(path: #{@groupfolder}, permissions: #{permissions}) failed: #{r.inspect}" }
    end

    def handle_project_folder(project_storage:)
      project_folder_id = project_storage.project_folder_id
      project = project_storage.project
      target = "#{@groupfolder}/#{project.name.gsub('/', '|')}(#{project.id})/"

      if file_ids.include?(project_folder_id)
        source = folders_props.find { |_k, v| v['fileid'] == project_folder_id }.first
        rename_folder(source:, target:) if source != target
      else
        create_folder(path: target, project_storage:)
      end
      @project_folder_ids_used_in_openproject << project_folder_id
      tokens = OAuthClientToken.where(oauth_client: @storage.oauth_client, users: project.users).includes(:user)
      set_project_folder_permissions(path: target, tokens:, project:)
      add_users_to_group(tokens)
    end

    def file_ids
      @file_ids ||= folders_props.map { |_path, props| props['fileid'] }
    end

    def folders_props
      @folders_props ||= @requests
                          .propfind_query
                          .call(depth: '1', path: @groupfolder, props: %w[oc:fileid])
                          .on_failure { |r| raise "propfind_query(depth: 1, path: #{@groupfolder}, props: #{%w[oc:fileid]}) failed: #{r.inspect}" }
                          .result
    end

    def rename_folder(source:, target:)
      @requests.rename_file_command.call(source:, target:).on_failure do |r|
        raise "rename_file_command failed(source: #{source} target: #{target}) failed: #{r.inspect}"
      end
    end

    def create_folder(path:, project_storage:)
      @requests.create_folder_command.call(folder_path: path)
        .match(
          on_success: ->(_) {
            folder_file_id = @requests
                               .propfind_query
                               .call(depth: '0', path:, props: %w[oc:fileid])
                               .on_failure { |r| raise "propfind_query failed: #{r}, depth: 0, path: #{path}" }
                               .result[path]['fileid']
            project_storage.update_columns(project_folder_id: folder_file_id, updated_at: Time.current)
          },
          on_failure: ->(r) { raise "create_folder_command(folder_path: #{target}) failed: #{r.inspect}, " }
        )
    end

    def remove_user_from_group(user)
      @requests
        .remove_user_from_group_command
        .call(user:)
        .on_failure { |r| raise "remove_user_from_group_command(user: #{user}) failed: #{r.inspect}" }
    end

    def inactive_project_folder_paths
      folders_props.except("#{@groupfolder}/").each_with_object([]) do |(path, attrs), paths|
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

    def set_project_folder_permissions(path:, tokens:, project:)
      @requests.set_permissions_command.call(path:, permissions: project_folder_permissions(tokens:, project:)).on_failure do |r|
        raise "set_permissions_command path(#{target}, permissions: #{permissions}) failed: #{r.inspect}"
      end
    end

    def add_users_to_group(tokens)
      tokens.each do |token|
        nextcloud_username = token.origin_user_id
        if group_users.exclude?(nextcloud_username) && @nextcloud_usernames_used_in_openproject.exclude?(nextcloud_username)
          @requests.add_user_to_group_command.call(user: nextcloud_username).on_failure do |r|
            raise "add_user_to_group_command(user: #{netcloud_username}) failed: #{r.inspect}, "
          end
        end
        @nextcloud_usernames_used_in_openproject << nextcloud_username
      end
    end

    def group_users
      @group_users ||= @requests.group_users_query.call(group: @group).on_failure do |r|
        raise "group_users_query(group: #{@group}) failed: #{r.inspect}"
      end.result
    end

    def project_folder_permissions(tokens:, project:)
      tokens.each_with_object({
                                users: { "#{@nextcloud_system_user}": ALL_PERMISSIONS },
                                groups: { "#{@group}": NO_PERMISSIONS }
                              }) do |token, permissions|
        nextcloud_username = token.origin_user_id
        permissions[:users][nextcloud_username.to_sym] = calculate_permissions(user: token.user, project:)
      end
    end
  end
end
