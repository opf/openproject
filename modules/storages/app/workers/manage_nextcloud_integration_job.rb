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

  PERMISSION_MAP = {
    read_files: 1,
    write_files: 2,
    create_files: 4,
    delete_files: 8,
    share_files: 16
  }.freeze

  queue_with_priority :low

  self.cron_expression = '*/5 * * * *'

  def perform
    Storages::NextcloudStorage.where("provider_fields->>'has_managed_project_folders' = 'true'").each do |storage|
      username = storage.username
      group = storage.group
      groupfolder = storage.groupfolder
      nextcloud_usernames_used_in_openprojects = Set.new
      project_folder_ids_used_in_openproject = Set.new

      requests = Storages::Peripherals::StorageRequests.new(storage:)

      group_users = requests.group_users_query.call(group:).on_failure do |r|
        raise "group_users_query failed: #{r.inspect}, group: #{group}"
      end.result

      requests.set_permissions_command.call(
        path: groupfolder,
        permissions: {
          users: { "#{username}": 31 },
          groups: { "#{group}": 1 }
        }
      ).on_failure do |r|
        raise "set_permissions_command failed: #{r}, path: #{path}, permissions: #{permissions}"
      end

      folders_props = requests
        .propfind_query
        .call(depth: '1', path: groupfolder)
        .on_failure { |r| raise "propfind_query failed: #{r}, depth: 1, path: #{groupfolder}" }
        .result
      file_ids = folders_props.map { |_path, props| props['fileid'] }

      storage.projects_storages.where(project_folder_mode: 'automatic').each do |project_storage|
        project_folder_id = project_storage.project_folder_id
        project = project_storage.project
        target = "#{groupfolder}/#{project.name.gsub('/', '|')}(#{project.id})/"

        if file_ids.include?(project_folder_id)
          source = folders_props.find { |_k, v| v['fileid'] == project_folder_id }.first
          if source != target
            requests.rename_file_command.call(source:, target:).on_failure do |r|
              raise "rename_file_command failed: #{r}, source: #{source} target: #{target}"
            end
          end
        else
          requests.create_folder_command.call(folder_path: target)
                  .match(
                    on_success: ->(_) {
                      propfind_response2 = requests
                                             .propfind_query
                                             .call(depth: '0', path: target)
                                             .match(
                                               on_success: ->(r) { r },
                                               on_failure: ->(r) {
                                                             raise "propfind_query failed: #{r}, depth: 0, path: #{target}"
                                                           }
                                             )
                      project_storage.update(project_folder_id: propfind_response2[target]['fileid'])
                    },
                    on_failure: ->(r) { raise "create_folder_command failed: #{r}, folder_path: #{target}" }
                  )
        end
        project_folder_ids_used_in_openproject << project_storage.project_folder_id
        project = project_storage.project
        project_users = project.users
        oauth_client = OAuthClient.where(integration_id: storage.id,
                                         integration_type: 'Storages::Storage').first
        tokens = OAuthClientToken.where(oauth_client:, user: project_users)
        permissions = {
          users: { "#{username}": 31 },
          groups: { "#{group}": 0 }
        }

        tokens.each do |token|
          nextcloud_username = token.origin_user_id
          permissions[:users][nextcloud_username.to_sym] = calculate_permissions(user: token.user, project:)

          if group_users.exclude?(nextcloud_username) && nextcloud_usernames_used_in_openprojects.exclude?(nextcloud_username)
            requests.add_user_to_group_command.call(user: nextcloud_username).on_failure do |r|
              raise "add_user_to_group_command failed: #{r}, user: #{netcloud_username}"
            end
          end
          nextcloud_usernames_used_in_openprojects << nextcloud_username
        end

        requests.set_permissions_command.call(path: target, permissions:).on_failure do |r|
          raise "set_permissions_command failed: #{r}, path: #{target}, permissions: #{permissions}"
        end
      end

      (group_users - nextcloud_usernames_used_in_openprojects.to_a).each do |user|
        requests.remove_user_from_group_command.call(user:)
                .on_failure { |r| raise "remove_user_from_group_command failed: #{r}, user: #{user}" }
      end

      lost_folder_paths = folders_props
                            .except("#{groupfolder}/")
                            .each_with_object([]) do |(path, attrs), array|
        array.push(path) if project_folder_ids_used_in_openproject.exclude?(attrs['fileid'])
      end
      lost_folder_paths.each do |path|
        requests.set_permissions_command.call(
          path:,
          permissions: {
            users: { "#{username}": 31 },
            groups: { "#{group}": 0 }
          }
        ).on_failure { |r| raise "set_permissions_command failed: #{r}, path: #{path}, permissions: #{permissions}" }
      end
    end
  end

  private

  def calculate_permissions(user:, project:)
    {
      read_files: user.allowed_to?(:read_files, project),
      write_files: user.allowed_to?(:write_files, project),
      create_files: user.allowed_to?(:create_files, project),
      share_files: user.allowed_to?(:share_files, project),
      delete_files: user.allowed_to?(:delete_files, project)
    }.reduce(0) do |acc, (k, v)|
      acc = acc + PERMISSION_MAP[k] if v
      acc
    end
  end
end
