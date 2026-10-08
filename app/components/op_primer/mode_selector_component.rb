# frozen_string_literal: true

module OpPrimer
  class ModeSelectorComponent < Primer::Component
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(title:, state:, description:, path:, button_label:, button_icon:, show_button: true,
                   alt_text: nil, method: :get, test_selector: "mode-selector")
      super()
      @title = title
      @state = state
      @description = description
      @path = path
      @button_label = button_label
      @button_icon = button_icon
      @show_button = show_button
      @alt_text = alt_text
      @method = method
      @test_selector = test_selector
    end
  end
end
