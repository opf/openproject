module Flash
  module Expectations
    # Expect a flash message to be present.
    #
    # A type and/or message text can be provided to add constraints on the
    # expectations.
    #
    # @param type [Symbol] the type of flash message. Can be :any, :error,
    #   :warning, :success or :notice (default: :any)
    # @param message [String, nil] the expected message text (default: nil)
    # @param wait [Integer] the maximum wait time for the flash in seconds (default: 20)
    def expect_flash(type: :any, message: nil, wait: 20)
      expected_css = expected_flash_css(type)
      expect(page).to have_css(expected_css, text: message, wait:)
    end

    # Find the flash element.
    #
    # @param type [Symbol] the type of flash message. Can be :any, :error,
    #   :warning, :success or :notice (default: :any)
    # @return [Capybara::Node::Element] the found flash element
    def find_flash_element(type: :any)
      expected_css = expected_flash_css(type)
      page.find(expected_css)
    end

    # Expect a flash message to be present and then dismiss it.
    #
    # A type and/or message text can be provided to add constraints on the
    # expectations.
    #
    # @param type [Symbol] the type of flash message. Can be :any, :error,
    #   :warning, :success or :notice (default: :any)
    # @param message [String, nil] the expected message text (default: nil)
    # @param wait [Integer] the maximum wait time for the flash in seconds (default: 20)
    def expect_and_dismiss_flash(type: :any, message: nil, wait: 20)
      expect_flash(type:, message:, wait:)
      dismiss_flash!
      expect_no_flash(type:, message:, wait: 0.1)
    end

    # Dismiss the flash message by clicking its close button.
    def dismiss_flash!
      find_flash_element.find(".Banner-close").click_button
    end

    # Expect that no flash message is present.
    #
    # A type and/or message text can be provided to add constraints on the
    # expectations.
    #
    # @param type [Symbol] the type of flash message. Can be :any, :error,
    #   :warning, :success or :notice (default: :any)
    # @param message [String, nil] the expected message text (default: nil)
    # @param wait [Integer] the maximum wait time for absence of the flash in seconds (default: 10)
    def expect_no_flash(type: :any, message: nil, wait: 10)
      expected_css = expected_flash_css(type)
      expect(page).to have_no_css(expected_css, text: message, wait:)
    end

    def expected_flash_css(type)
      scheme = mapped_flash_type(type)
      case scheme
      when :any
        %{[data-test-selector="op-primer-flash-message"].Banner}
      else
        %{[data-test-selector="op-primer-flash-message"].Banner--#{scheme}}
      end
    end

    def mapped_flash_type(type)
      case type
      when :error
        :error # The class is error, but the scheme is danger
      when :warning
        :warning
      when :success, :notice
        :success
      else
        :any
      end
    end
  end
end

RSpec.configure do |config|
  config.include Flash::Expectations
end
