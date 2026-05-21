# frozen_string_literal: true

module Mngt
  class SyncPeopleJob < ApplicationJob
    queue_as :default

    def perform
      Mngt::UserSyncService.sync_all
    end
  end
end
