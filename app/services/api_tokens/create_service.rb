# frozen_string_literal: true

module APITokens
  class CreateService < BaseServices::Create
    private

    def instance_class
      Token::API
    end
  end
end
