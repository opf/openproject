module API::V3::Utilities::StorageInteraction
  class NextcloudStorageQuery
    def initialize(base_uri:, token:, token_refresh:)
      @uri = base_uri
      @token = token
      @token_refresh = token_refresh
      @base_path = "/remote.php/dav/files/#{@token.origin_user_id}/"
    end

    def files
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = @uri.scheme == 'https'

      result = @token_refresh.call do
        response = http.propfind(
          @base_path,
          nil,
          {
            'Depth' => '1',
            'Authorization' => "Bearer #{@token.access_token}"
          }
        )

        if %w[401 403].include?(response.code)
          ServiceResult.failure(result: :not_authorized)
        else
          ServiceResult.success(result: response.body)
        end
      end

      parse_response(result)
    end

    private

    def parse_response(response)
      return response unless response.success

      Nokogiri::XML(response.result)
        .xpath('//d:response')
        .drop(1) # drop current directory
        .map { |file_element| storage_file(file_element) }
    end

    def storage_file(file_element)
      name = name(file_element)

      ::Storages::StorageFile.new(
        nil,
        CGI.unescape(name),
        mime_type(file_element),
        nil,
        last_modified_at(file_element),
        nil,
        nil,
        "/#{name}"
      )
    end

    def name(response)
      response
        .xpath('d:href')
        .first
        .inner_text
        .delete_prefix(@base_path)
        .delete_suffix('/')
    end

    def mime_type(response)
      response
        .xpath('.//d:getcontenttype')
        .first
        .inner_text
    rescue NoMethodError
      'application/x-op-directory'
    end

    def last_modified_at(response)
      response
        .xpath('.//d:getlastmodified')
        .map { |e| DateTime.parse(e) }
        .first
    end
  end
end
