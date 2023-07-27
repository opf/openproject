module Storages
  module Peripherals
    module StorageInteraction
      module Nextcloud
        Queries = Dry::Container::Namespace.new('queries') do
          namespace('nextcloud') do
            register(:file_query, FileQuery.new)
            register(:download_link_query) { DownloadLinkQuery }
            register(:files_query, FilesQuery.new)
            register(:upload_link_query) { UploadLinkQuery }
            register(:group_users_query) { GroupUsersQuery }
            register(:propfind_query) { PropfindQuery }
          end
        end
      end
    end

    Registry.import StorageInteraction::Nextcloud::Queries
  end
end
