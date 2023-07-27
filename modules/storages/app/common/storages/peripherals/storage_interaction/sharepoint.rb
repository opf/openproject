module Storages
  module Peripherals
    module StorageInteraction
      module Sharepoint
        Queries = Dry::Container::Namespace.new('queries') do
          namespace('sharepoint') do
            register(:file_query, 10)
            # register(:download_link_query) { DownloadLinkQuery }
            # register(:files_query) { FilesQuery }
            # register(:upload_link_query) { UploadLinkQuery }
            # register(:group_users_query) { GroupUsersQuery }
            # register(:propfind_query) { PropfindQuery }
          end
        end
      end
    end

    Registry.import StorageInteraction::Sharepoint::Queries
  end
end
