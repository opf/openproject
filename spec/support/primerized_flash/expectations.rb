module PrimerizedFlash
  module Expectations
    def expect_primerized_error(message)
      expect_primerized_flash(message:, type: :error)
    end

    def expect_primerized_flash(message:, type: :success, wait: 20)
      expected_css = expected_flash_css(type)
      expect(page).to have_css(expected_css, text: message, wait:)
    end

    def find_primerized_flash(type:)
      expected_css = expected_flash_css(type)
      page.find(expected_css)
    end

    def expect_and_dismiss_primerized_flash(message: nil, type: :success, wait: 20)
      expect_primerized_flash(type:, message:, wait:)
      dismiss_primerized_flash!
      expect_no_primerized_flash(type:, message:, wait: 0.1)
    end

    def dismiss_primerized_flash!
      page.find(".Banner-close button").click # rubocop:disable Capybara/SpecificActions
    end

    # Clears a toaster if there is one waiting 1 second max, but do not fail if there is none
    def clear_primerized_flashes
      if has_css?(".Banner-close button")
        dismiss_primerized_flash!
      end
    end

    def expect_no_primerized_flash(type: :success, message: nil, wait: 10)
      if type.nil?
        expect(page).not_to have_test_selector("op-primer-flash-message")
      else
        expected_css = expected_flash_css(type)
        expect(page).to have_no_css(expected_css, text: message, wait:)
      end
    end

    def expected_flash_css(type)
      scheme = mapped_flash_type(type)
      case scheme
      when :default
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
        :default
      end
    end
  end
end

RSpec.configure do |config|
  config.include PrimerizedFlash::Expectations
end
