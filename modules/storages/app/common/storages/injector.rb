# frozen_string_literal: true

require "dry/auto_inject"

module Storages
  Injector = Dry::AutoInject(Peripherals::Registry)
end
