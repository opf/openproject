module API
  module OpenAPI
    def self.spec(version: :stable)
      API::OpenAPI::BlueprintImport.convert version: version
    end
  end
end
