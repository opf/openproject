module Storages
  module Peripherals
    class Registry
      extend Dry::Container::Mixin
    end

    require_relative 'storage_interaction/nextcloud'
    require_relative 'storage_interaction/sharepoint'
  end
end
