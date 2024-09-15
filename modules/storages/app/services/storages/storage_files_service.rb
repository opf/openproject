# frozen_string_literal: true

#-- copyright
#++

module Storages
  class StorageFilesService < BaseService
    def self.call(storage:, user:, folder:)
      new.call(storage:, user:, folder:)
    end

    def call(user:, storage:, folder:)
      auth_strategy = strategy(storage, user)

      Peripherals::Registry.resolve("#{storage}.queries.files").call(storage:, auth_strategy:, folder:)
    end

    private

    def strategy(storage, user)
      Peripherals::Registry.resolve("#{storage}.authentication.user_bound").call(user:)
    end
  end
end
