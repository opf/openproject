# frozen_string_literal: true

module Grape
  module Middleware
    # Common methods for all types of Grape middleware
    module Helpers
      def context
        env[Grape::Env::API_ENDPOINT]
      end
    end
  end
end
