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
  class UploadFileService < BaseService
    using Peripherals::ServiceResultRefinements

    def self.call(container:, project_storage:, file_path:, filename:, file_data:)
      new(project_storage, container).call(file_path:, filename:, file_data:)
    end

    def initialize(project_storage, container)
      super()
      @project_storage = project_storage
      @storage = project_storage.storage
      @container = container
      @user = determine_user(container)
    end

    def call(file_path:, filename:, file_data:)
      with_tagged_logger do
        info "Starting file upload for #{filename} to #{file_path}"

        unless @storage.provider_type_nextcloud?
          @result.errors.add(:base, :unsupported_storage_type)
          @result.success = false
          return @result
        end

        fetch_or_create_folder(file_path).bind do |folder|
          upload_file(folder, filename, file_data).bind do |file|
            create_file_link(file)
          end
        end

        @result
      end
    end

    private

    def auth_strategy = Adapters::Registry["#{@storage}.authentication.userless"].call

    def error_with_code(error, code)
      Adapters::Results::Error.new(payload: error.payload, source: self.class).with(code: code)
    end

    def determine_user(container)
      return container.author if container.respond_to?(:author) && container.author

      User.system
    end

    def fetch_or_create_folder(file_path)
      prefix = @project_storage.managed_project_folder_path
      current_folder = nil

      cumulative_paths(prefix, file_path).each do |folder_path|
        current_folder = check_folder_exists(folder_path).or do |error|
          if error.code == :not_found
            create_folder!(folder_path)
          else
            add_error(:base, error)
            return Failure(:storage_error)
          end
        end
      end
      current_folder
    end

    def cumulative_paths(prefix, path)
      segments = path.split("/").reject(&:empty?)
      return [prefix] if segments.empty?

      segments.map.with_index { |_, i| "#{prefix}#{segments[0..i].join('/')}" }
    end

    def check_folder_exists(path)
      input_data = Adapters::Input::Files.build(folder: path).value_or do |error|
        add_validation_error(error, options: { folder_path: path })
        return Failure(:invalid_input)
      end

      Adapters::Registry
        .resolve("#{@storage}.queries.files")
        .call(auth_strategy:, storage: @storage, input_data:)
        .bind { |files_collection| Success(files_collection.parent) }
    end

    def create_folder!(path)
      folder_path = File.dirname(path)
      folder_name = path.delete_prefix("#{folder_path}/")

      input_data = Adapters::Input::CreateFolder.build(folder_name:, parent_location: folder_path).value_or do |error|
        add_validation_error(error, options: { folder_path: folder_path })
        return Failure(:invalid_input)
      end
      Adapters::Registry["#{@storage}.commands.create_folder"].call(storage: @storage, auth_strategy:, input_data:).or do |error|
        add_error(:base, error, options: { folder_path: folder_path })
        Failure(:storage_error)
      end
    end

    def upload_file(folder, filename, file_data)
      input_data = Adapters::Input::UploadFile.build(
        parent_location: folder.location,
        file_name: filename,
        io: file_data
      ).value_or do |error|
        add_validation_error(error, options: { file_path: "#{folder.location}/#{filename}" })
        return Failure(:invalid_input)
      end

      Adapters::Registry["#{@storage.short_provider_type}.commands.upload_file"]
        .call(storage: @storage, auth_strategy:, input_data:).or do |error|
          add_error(:base, error, options: { file_path: "#{folder.location}/#{filename}" })
          Failure(:storage_error)
        end
    end

    def create_file_link(file_info)
      info "Creating FileLink for file #{file_info.id}"

      file_link_params = {
        creator: @user,
        container: @container,
        origin_id: file_info.id,
        origin_name: file_info.name,
        origin_mime_type: file_info.mime_type,
        storage: @storage
      }

      file_link_result = FileLinks::CreateService
        .new(user: @user, contract_class: FileLinks::CreateContract)
        .call(file_link_params)
      @result.result = file_link_result.result if file_link_result.success?
      @result.merge!(file_link_result)
    end
  end
end
