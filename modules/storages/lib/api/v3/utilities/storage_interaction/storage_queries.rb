module API::V3::Utilities::StorageInteraction
  class StorageQueries
    using ::API::V3::Utilities::ServiceResultRefinements

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
        connection_manager.get_access_token.match(
          on_success: ->(token) do
            ServiceResult.success(
              result:
                ::API::V3::Utilities::StorageInteraction::NextcloudStorageQuery.new(
                  base_uri: @uri,
                  origin_user_id: token.origin_user_id,
                  token: token.access_token,
                  with_refreshed_token: connection_manager.method(:with_refreshed_token).to_proc
                )
            )
          end,
          on_failure: ->(_) do
            ServiceResult.failure(result: :not_authorized)
          end
        )
      else
        raise ArgumentError
      end
    end
  end
end
