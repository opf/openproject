module API::V3::Utilities::StorageInteraction
  class StorageQueries
    def initialize(uri:, provider_type:, user:, oauth_client:)
      @uri = uri
      @provider_type = provider_type
      @user = user
      @oauth_client = oauth_client
    end

    def files_query
      case @provider_type
      when ::Storages::Storage::PROVIDER_TYPE_NEXTCLOUD
        connection_manager = ::OAuthClients::ConnectionManager.new(user: @user, oauth_client: @oauth_client)
        token = connection_manager.get_access_token.result

        ::API::V3::Utilities::StorageInteraction::NextcloudStorageQuery.new(
          base_uri: @uri,
          token:,
          token_refresh: ->(&block) {
            connection_manager.request_with_token_refresh(token) do
              block.call
            end
          }
        )
      else
        raise ArgumentError
      end
    end
  end
end
