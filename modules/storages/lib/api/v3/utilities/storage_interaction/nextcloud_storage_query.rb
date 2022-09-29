module API::V3::Utilities::StorageInteraction
  class NextcloudStorageQuery
    def initialize(base_uri:, token:, token_refresh:)
      @uri = base_uri
      @token = token
      @token_refresh = token_refresh
      @base_path = "/remote.php/dav/files/#{@token.send('origin_user_id')}/"
    end

    def files
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = @uri.scheme == 'https'

      result = @token_refresh.call do
        response = http.propfind(
          @base_path,
          requested_properties,
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

    def requested_properties
      Nokogiri::XML::Builder.new do |xml|
        xml['d'].propfind(
          'xmlns:d' => 'DAV:',
          'xmlns:oc' => 'http://owncloud.org/ns'
        ) do
          xml['d'].send('prop') do
            xml['oc'].send('fileid')
            xml['oc'].send('size')
            xml['d'].send('getcontenttype')
            xml['d'].send('getlastmodified')
            xml['oc'].send('owner-display-name')
          end
        end
      end.to_xml
    end

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
        id(file_element),
        CGI.unescape(name),
        size(file_element),
        mime_type(file_element),
        nil,
        last_modified_at(file_element),
        created_by(file_element),
        nil,
        "/#{name}"
      )
    end

    def id(element)
      element
        .xpath('.//oc:fileid')
        .map(&:inner_text)
        .reject(&:empty?)
        .first
    end

    def name(element)
      element
        .xpath('d:href')
        .map(&:inner_text)
        .first
        .delete_prefix(@base_path)
        .delete_suffix('/')
    end

    def size(element)
      element
        .xpath('.//oc:size')
        .map(&:inner_text)
        .map { |e| Integer(e) }
        .first
    end

    def mime_type(element)
      element
        .xpath('.//d:getcontenttype')
        .map(&:inner_text)
        .reject(&:empty?)
        .first || 'application/x-op-directory'
    end

    def last_modified_at(element)
      element
        .xpath('.//d:getlastmodified')
        .map { |e| DateTime.parse(e) }
        .first
    end

    def created_by(element)
      element
        .xpath('.//oc:owner-display-name')
        .map(&:inner_text)
        .reject(&:empty?)
        .first
    end
  end
end
