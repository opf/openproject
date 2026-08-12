# frozen_string_literal: true

module Flash
  module Expectations
    def expect_flash(message: nil, exact_message: nil, type: :success, wait: 20)
      expected_css = expected_flash_css(type)
      expect(page).to have_css(expected_css, wait:, **{ text: message, exact_text: exact_message }.compact)
    end

    def find_flash_element(type:)
      expected_css = expected_flash_css(type)
      page.find(expected_css)
    end

    def expect_and_dismiss_flash(message: nil, exact_message: nil, type: :success, wait: 20)
      expect_flash(type:, message:, exact_message:, wait:)
      dismiss_flash!
      expect_no_flash(type:, message:, exact_message:, wait: 5)
    end

    def dismiss_flash!
      page.find(".Banner-close button").click # rubocop:disable Capybara/SpecificActions
    end

    def expect_no_flash(type: :success, message: nil, exact_message: nil, wait: 10)
      if type.nil?
        expect(page).to have_no_test_selector("op-primer-flash-message")
      else
        expected_css = expected_flash_css(type)
        expect(page).to have_no_css(expected_css, wait:, **{ text: message, exact_text: exact_message }.compact)
      end
    end

    def expected_flash_css(type)
      scheme = mapped_flash_type(type)

      if scheme == :default
        %{[data-test-selector="op-primer-flash-message"].Banner}
      else
        %{[data-test-selector="op-primer-flash-message"].Banner--#{scheme}}
      end
    end

    def mapped_flash_type(type)
      case type
      when :error, :warning, :success
        type
      when :notice
        :success
      else
        :default
      end
    end
  end
end

RSpec.configure do |config|
  config.include Flash::Expectations
end
