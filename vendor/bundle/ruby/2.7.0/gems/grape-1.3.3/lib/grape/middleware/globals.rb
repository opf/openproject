# frozen_string_literal: true

require 'grape/middleware/base'

module Grape
  module Middleware
    class Globals < Base
      def before
        request = Grape::Request.new(@env, build_params_with: @options[:build_params_with])
        @env[Grape::Env::GRAPE_REQUEST] = request
        @env[Grape::Env::GRAPE_REQUEST_HEADERS] = request.headers
        @env[Grape::Env::GRAPE_REQUEST_PARAMS] = request.params if @env[Grape::Env::RACK_INPUT]
      end
    end
  end
end
