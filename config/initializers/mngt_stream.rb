# frozen_string_literal: true

module Mngt
  module Stream
    # Public API key — safe to expose to the browser.
    def self.api_key
      ENV.fetch("MNGT_STREAM_API_KEY", "")
    end

    # Private API secret — server-side only, never sent to the browser.
    def self.api_secret
      ENV.fetch("MNGT_STREAM_API_SECRET", "")
    end

    def self.configured?
      api_key.present? && api_secret.present?
    end
  end
end
