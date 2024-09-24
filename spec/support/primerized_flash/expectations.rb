module PrimerizedFlash
  module Expectations
    include FlashMessagesHelper

    def expect_primerized_flash(message:, type: :success, wait: 20)
      mapped_scheme = mapped_flash_type(type)
      expect(page).to have_css(".Banner--#{mapped_scheme}", text: message, wait:)
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
        mapped_scheme = mapped_flash_type(type)
        expect(page).to have_no_css(".Banner--#{mapped_scheme}", text: message, wait:)
      end
    end
  end
end

RSpec.configure do |config|
  config.include PrimerizedFlash::Expectations
end
