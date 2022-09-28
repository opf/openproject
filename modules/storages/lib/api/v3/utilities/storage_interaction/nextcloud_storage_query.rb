module API::V3::Utilities::StorageInteraction
  class NextcloudStorageQuery
    def initialize(base_uri:, token:, token_refresh:)
      @uri = base_uri
      @token = token
      @token_refresh = token_refresh
    end

    def files
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = @uri.scheme == 'https'

      path = "/remote.php/dav/files/#{@token.origin_user_id}/"

      result = @token_refresh.call do
        response = http.propfind(
          path,
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

      parse_response(result, path)
    end

    private

    def parse_response(response, base)
      return response unless response.success

      document = Nokogiri::XML(response.result)
      elements = document.xpath('//d:href')

      elements.drop(1).map do |e|
        normalized_name = e.children.first.to_s.delete_prefix(base)

        ::Storages::StorageFile.new(
          nil,
          CGI.unescape(normalized_name),
          'text/plain',
          nil,
          nil,
          nil,
          nil,
          "/#{normalized_name}"
        )
      end
    end
  end
end
