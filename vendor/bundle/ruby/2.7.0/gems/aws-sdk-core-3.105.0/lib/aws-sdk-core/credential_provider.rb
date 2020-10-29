# frozen_string_literal: true

module Aws
  module CredentialProvider

    # @return [Credentials]
    attr_reader :credentials

    # @return [Boolean]
    def set?
      !!credentials && credentials.set?
    end

  end
end
