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
      module OneDrive
        module Validators
          class AmpfConfigurationValidator < HealthReports::ValidatorGroup
            include TaggedLogging

            TEST_FOLDER_NAME = "OpenProjectConnectionValidationFolder"

            def self.key = :ampf_configuration

            private

            def validate
              register_checks :client_folder_creation, :client_folder_removal, :drive_contents

              client_permissions
              unexpected_content
            end

            def unexpected_content
              files = files_query.value_or { fail_check(:drive_contents, :unknown_error) }
              unexpected_files = files.reject { managed_project_folder_ids.include?(it.id) }

              if unexpected_files.empty?
                pass_check(:drive_contents)
              else
                log_extraneous_files(unexpected_files)
                warn_check(:drive_contents, :od_unexpected_content)
              end
            end

            # Testing setting permissions and checking permission inheritance would be great,
            # but there are some challenges to it. We need to figure out a good way to go about this
            # 2025-04-08 @mereghost
            def client_permissions
              folder = create_folder.value!
              delete_folder(folder)
            end

            def delete_folder(folder)
              Input::DeleteFolder.build(location: folder.id).bind do |input_data|
                Registry["one_drive.commands.delete_folder"].call(storage: subject, auth_strategy:, input_data:)
                  .either(->(_) { pass_check(:client_folder_removal) },
                          ->(_) { fail_check(:client_folder_removal, :od_client_cant_delete_folder) })
              end
            end

            def create_folder
              Input::CreateFolder.build(folder_name: TEST_FOLDER_NAME, parent_location: "/").bind do |input_data|
                folder_result = Registry["one_drive.commands.create_folder"].call(storage: subject, auth_strategy:, input_data:)

                folder_result.either(
                  ->(_) { pass_check(:client_folder_creation) },
                  ->(error) do
                    code = error.code == :conflict ? :od_existing_test_folder : :od_client_write_permission_missing
                    fail_check(:client_folder_creation, code, context: { folder_name: TEST_FOLDER_NAME })
                  end
                )

                folder_result
              end
            end

            def log_extraneous_files(unexpected_files)
              file_representation = unexpected_files.map do |file|
                "Name: #{file.name}, ID: #{file.id}, Location: #{file.location}"
              end

              warn "Unexpected files/folder found in drive root folder:\n\t#{file_representation.join("\n\t")}"
            end

            def managed_project_folder_ids
              @managed_project_folder_ids ||= ProjectStorage.automatic.where(storage: subject)
                                                            .pluck(:project_folder_id).to_set
            end

            def files_query
              Input::Files
                .build(folder: "/")
                .bind { Registry["one_drive.queries.files"].call(storage: subject, auth_strategy:, input_data: it) }
            end

            def auth_strategy = Registry["one_drive.authentication.userless"].call
          end
        end
      end
    end
  end
end
