# frozen_string_literal: true

module Grape
  module Parser
    module Json
      class << self
        def call(object, _env)
          ::Grape::Json.load(object)
        rescue ::Grape::Json::ParseError
          # handle JSON parsing errors via the rescue handlers or provide error message
          raise Grape::Exceptions::InvalidMessageBody, 'application/json'
        end
      end
    end
  end
end
