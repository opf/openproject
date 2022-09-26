module API::V3::Utilities::StorageInteraction
  class AbstractStorageQuery
    def files
      raise NotImplementedError
    end
  end
end
