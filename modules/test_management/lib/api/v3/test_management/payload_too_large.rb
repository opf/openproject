# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # 413 for reports above IngestService::MAX_BYTES (core has no such error class).
      class PayloadTooLarge < ::API::Errors::ErrorBase
        identifier "PayloadTooLarge"
        code 413
      end
    end
  end
end
