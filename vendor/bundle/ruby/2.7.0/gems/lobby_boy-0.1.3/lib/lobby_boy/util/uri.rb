require 'uri'

module LobbyBoy
  module Util
    module URI
      module_function

      def add_query_params(url, additional_params = {})
        return nil if url.nil?

        uri = ::URI.parse url.to_s
        params = ::URI.decode_www_form(uri.query || '')

        additional_params.each do |name, value|
          if value
            params.delete_if { |param_name, _| param_name == name.to_s } # override existing

            params << [name.to_s, value]
          end
        end

        uri.query = ::URI.encode_www_form params
        uri.to_s
      end
    end
  end
end
