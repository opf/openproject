module Storages
  module Peripherals
    class Registry
      extend Dry::Container::Mixin
    end

    Registry.import StorageInteraction::Nextcloud::Queries
    Registry.import StorageInteraction::Nextcloud::Commands
  end
end
