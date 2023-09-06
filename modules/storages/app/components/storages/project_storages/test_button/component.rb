# frozen_string_literal: true

module Storages::ProjectStorages::TestButton
  class Component < ApplicationComponent
    def initialize(label:)
      @label = label
      super
    end
  end
end
