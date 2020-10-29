module Fog
  module AWS
    class Storage
      class Real
        # Sync clock against S3 to avoid skew errors
        #
        def sync_clock
          response = begin
            get_service
          rescue Excon::Errors::HTTPStatusError => error
            error.response
          end
          Fog::Time.now = Time.parse(response.headers['Date'])
        end
      end # Real

      class Mock # :nodoc:all
        def sync_clock
          true
        end
      end # Mock
    end # Storage
  end # AWS
end # Fog
