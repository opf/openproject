# frozen_string_literal: true

module Doorkeeper
  class TokenInfoController < Doorkeeper::ApplicationMetalController
    def show
      if doorkeeper_token&.accessible?
        render json: doorkeeper_token, status: :ok
      else
        error = OAuth::InvalidTokenResponse.new
        response.headers.merge!(error.headers)
        render json: error.body, status: error.status
      end
    end
  end
end
