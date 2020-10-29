# frozen_string_literal: true

module Doorkeeper
  module OAuth
    module Hooks
      class Context
        attr_reader :auth, :pre_auth

        def initialize(**attributes)
          attributes.each do |name, value|
            instance_variable_set(:"@#{name}", value) if respond_to?(name)
          end
        end

        def issued_token
          auth&.issued_token
        end
      end
    end
  end
end
