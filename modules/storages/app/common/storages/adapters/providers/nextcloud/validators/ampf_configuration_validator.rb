# frozen_string_literal: true

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

module Storages
  module Adapters
    module Providers
      module Nextcloud
        module Validators
          class AmpfConfigurationValidator < HealthReports::ValidatorGroup
            include TaggedLogging

            def self.key = :ampf_configuration

            private

            def validate
              register_checks(
                :team_folder_app,
                :files_request,
                :userless_access,
                :team_folder_presence,
                :project_folders_linked,
                :project_folders_exist,
                :team_folder_contents
              )

              team_folder_app_checks
              files_request_failed_with_unknown_error
              userless_access_denied
              team_folder_not_found
              project_folders_linked
              project_folders_exist
              with_unexpected_content
            end

            def userless_access_denied
              files.or { it.code == :unauthorized and fail_check(:userless_access, :nc_userless_access_denied) }
              pass_check(:userless_access)
            end

            def team_folder_app_checks
              required_version = SemanticVersion.parse(
                nextcloud_dependencies.dig("dependencies", "team_folders_app", "min_version")
              )

              capabilities = Registry["nextcloud.queries.capabilities"].call(storage: subject, auth_strategy: noop).value!
              dependency = I18n.t("storages.dependencies.nextcloud.group_folders_app")

              if capabilities.group_folder_disabled?
                fail_check(:team_folder_app, :nc_dependency_missing, context: { dependency: })
              elsif capabilities.group_folder_version < required_version
                warn_check(:team_folder_app, :nc_dependency_version_mismatch, context: { dependency: })
              else
                pass_check(:team_folder_app)
              end
            end

            def team_folder_not_found
              files.or { it.code == :not_found and fail_check(:team_folder_presence, :nc_team_folder_not_found) }
              pass_check(:team_folder_presence)
            end

            def files_request_failed_with_unknown_error
              files.or do |failure|
                if failure.code == :error
                  error "Connection validation failed with unknown error:\n" \
                        "\tstorage: ##{subject.id} #{subject.name}\n" \
                        "\trequest: Team folder content\n" \
                        "\tstatus: #{failure}\n" \
                        "\tresponse: #{failure.payload}"

                  fail_check(:files_request, :unknown_error)
                end
              end
              pass_check(:files_request)
            end

            def project_folders_linked
              ampf_project_storages = subject.project_storages.active.automatic
              expected = ampf_project_storages.count
              actual = ampf_project_storages.with_project_folder.count
              return pass_check(:project_folders_linked) if actual == expected

              warn_check(:project_folders_linked, :nc_unlinked_project_folders, context: { actual:, expected: })
            end

            def project_folders_exist
              subject.project_storages.active.automatic.with_project_folder.each do |project_storage|
                next if existing_folder_ids.include?(project_storage.project_folder_id)

                return fail_check(
                  :project_folders_exist, :nc_project_folder_missing, context: { project: project_storage.project.name }
                )
              end

              pass_check(:project_folders_exist)
            end

            def with_unexpected_content
              unexpected_files = files.value!.reject { managed_project_folder_ids.include?(it.id) }
              return pass_check(:team_folder_contents) if unexpected_files.empty?

              log_extraneous_files(unexpected_files)
              warn_check(:team_folder_contents, :nc_unexpected_files, context: { sample: unexpected_files.sample.name })
            end

            def log_extraneous_files(unexpected_files)
              file_representation = unexpected_files.map do |file|
                "Name: #{file.name}, ID: #{file.id}, Location: #{file.location}"
              end

              warn "Unexpected files/folder found in team folder:\n\t#{file_representation.join("\n\t")}"
            end

            def auth_strategy = Registry["nextcloud.authentication.userless"].call

            def managed_project_folder_ids
              @managed_project_folder_ids ||= ProjectStorage.automatic.where(storage: subject)
                                                            .pluck(:project_folder_id).to_set
            end

            def files
              @files ||= Input::Files.build(folder: subject.group_folder).bind do |input_data|
                Registry.resolve("#{subject}.queries.files").call(storage: subject, auth_strategy:, input_data:)
              end
            end

            def existing_folder_ids
              @existing_folder_ids ||= files.value!.all_folders.to_set(&:id)
            end

            def noop = Input::Strategy.build(key: :noop)

            def nextcloud_dependencies
              @nextcloud_dependencies ||= YAML.load_file(path_to_config).deep_stringify_keys
            end

            def path_to_config = Rails.root.join("modules/storages/config/nextcloud_dependencies.yml")
          end
        end
      end
    end
  end
end
