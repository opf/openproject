# frozen_string_literal: true

#-- copyright
#++

module Storages
  class CopyProjectFoldersJob < ApplicationJob
    # include GoodJob::ActiveJobExtensions::Batches

    retry_on Errors::PollingRequired, wait: 3, attempts: :unlimited
    # discard_on HTTPX::HTTPError

    def perform(user_id:, source_id:, target_id:, work_package_map:)
      target = ProjectStorage.find(target_id)
      source = ProjectStorage.find(source_id)
      user = User.find(user_id)
      new_work_package_map = work_package_map.transform_keys(&:to_i)

      project_folder_result = if polling?
                                results_from_polling
                              else
                                initiate_project_folder_copy(source, target)
                              end

      project_folder_id = project_folder_result.on_failure { |failed_result| return failed_result }.result

      # TODO: Do Something when this fails
      ProjectStorages::UpdateService.new(user:, model: target)
                                    .call(project_folder_id:, project_folder_mode: source.project_folder_mode)

      # We only get here on a successful execution
      create_target_file_links(source, target, new_work_package_map, user)
    end

    private

    def create_target_file_links(source, target, work_package_map, user)
      source_file_links = FileLink
        .includes(:creator)
        .where(container_id: work_package_map.keys, container_type: "WorkPackage")

      return create_unmanaged_file_links(source_file_links, work_package_map, user) if source.project_folder_manual?

      target_files = Peripherals::Registry
        .resolve("#{source.storage.short_provider_type}.queries.folder_files_file_ids_deep_query")
        .call(storage: source.storage, folder: Peripherals::ParentFolder.new(target.project_folder_location))
        .result

      source_files = Peripherals::Registry
        .resolve("#{source.storage.short_provider_type}.queries.files_info")
        .call(storage: source.storage, user:, file_ids: source_file_links.pluck(:origin_id))
        .result

      source_location_map = source_files.to_h { |info| [info.id, info.location] }

      source_file_links.find_each do |source_link|
        attributes = source_link.dup.attributes

        attributes['creator_id'] = user.id
        attributes['container_id'] = work_package_map[source_link.container_id]

        source_link_location = source_location_map[source_link.origin_id]
        target_link_location = source_link_location.gsub(source.managed_project_folder_path, target.managed_project_folder_path)

        attributes['origin_id'] = target_files[target_link_location]

        FileLinks::CreateService.new(user:).call(attributes)
      end
    end

    def create_unmanaged_file_links(source_file_links, work_package_map, user)
      source_file_links.find_each do |source_file_link|
        attributes = source_file_link.dup.attributes

        attributes['creator_id'] = user.id
        attributes['container_id'] = work_package_map[source_file_link.container_id]

        # TODO: Do something when this fails
        FileLinks::CreateService.new(user:).call(attributes)
      end
    end

    def initiate_project_folder_copy(source, target)
      return ServiceResult.success if source.project_folder_inactive?
      return ServiceResult.success(result: source.project_folder_id) if source.project_folder_manual?

      copy_result = issue_command(source, target).on_failure { |failed_result| return failed_result }.result
      return ServiceResult.success(result: copy_result[:id]) if copy_result[:id]

      Thread.current[job_id] = copy_result[:url]
      raise Errors::PollingRequired, "#{job_id} Storage requires polling"
    end

    def issue_command(source, target)
      Peripherals::Registry
        .resolve("#{source.storage.short_provider_type}.commands.copy_template_folder")
        .call(storage: source.storage,
              source_path: source.project_folder_location,
              destination_path: target.managed_project_folder_path)
    end

    def polling?
      !!Thread.current[job_id]
    end

    def results_from_polling
      # TODO: Maybe Transform this in a Query
      response = OpenProject.httpx.get(Thread.current[job_id]).json(symbolize_keys: true)

      raise(Errors::PollingRequired, "#{job_id} Polling not completed yet") if response[:status] != 'completed'

      Thread.current[job_id] = nil
      ServiceResult.success(result: response[:resourceId])
    end
  end
end
