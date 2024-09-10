# frozen_string_literal: true

#-- copyright
#++

module Storages
  class UploadLinkService < BaseService
    def self.call(user:, storage:, upload_data:)
      new(storage).call(user:, upload_data:)
    end

    def initialize(storage)
      super()
      @storage = storage
    end

    def call(user:, upload_data:)
      with_tagged_logger do
        info "Validating upload information"
        input = validate_input(**upload_data).value_or { return @result }

        info "Upload data validated..."
        info "Requesting an upload link to #{@storage.name}"
        upload_link = request_upload_link(auth_strategy(user), input).on_failure { return @result }.result

        @result.result = upload_link
        @result
      end
    end

    private

    def request_upload_link(auth_strategy, upload_data)
      Peripherals::Registry
        .resolve("#{@storage.short_provider_type}.queries.upload_link")
        .call(storage: @storage, auth_strategy:, upload_data:)
        .on_failure do |error|
        add_error(:base, error.errors, options: { storage_name: @storage.name, folder: upload_data.folder_id })
        log_storage_error(error.errors)
        @result.success = false
      end
    end

    def validate_input(...)
      Peripherals::StorageInteraction::Inputs::UploadData.build(...).alt_map do |failure|
        error failure.inspect
        @result.add_error(:base, :invalid, options: failure.to_h)
        @result.success = false
      end
    end

    def auth_strategy(user)
      Peripherals::Registry.resolve("#{@storage.short_provider_type}.authentication.userbound").call(user:)
    end
  end
end
