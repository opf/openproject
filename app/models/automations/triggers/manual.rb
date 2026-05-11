# frozen_string_literal: true

module Automations
  module Triggers
    class Manual < Base
      store_attribute :options, :button_label, :string

      validates :button_label, presence: true, length: { maximum: 255 }
    end
  end
end
