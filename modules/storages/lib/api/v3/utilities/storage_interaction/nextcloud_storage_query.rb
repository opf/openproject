module API::V3::Utilities::StorageInteraction
  class NextcloudStorageQuery < AbstractStorageQuery
    def files
      ::Storages::StorageFile.all
    end
  end
end
