# frozen_string_literal: true

module Toasts
  module Expectations
    def expect_toast(message:, type: :success, wait: 20)
      expect(page).to have_css(".op-toast.-#{type}", text: message, wait:)
    end

    def expect_and_dismiss_toaster(message: nil, type: :success, wait: 20)
      expect_toast(type:, message:, wait:)
      dismiss_toaster!
      expect_no_toaster(type:, message:, wait: 0.1)
    end

    # Like #expect_and_dismiss_toaster, but tolerant of a single user action raising
    # several identical toasts (e.g. a grid change that persists in multiple steps).
    # Dismisses every matching toast, allowing late ones to still appear, before
    # asserting that none remain.
    def expect_and_dismiss_all_toasters(message: nil, type: :success, wait: 20)
      expect_toast(type:, message:, wait:)

      while page.has_css?(".op-toast.-#{type}", wait: 1)
        page.first(".op-toast.-#{type} .op-toast--close", wait: 1).click
      end

      expect_no_toaster(type:, message:, wait: 2)
    end

    def dismiss_toaster!
      sleep 0.1
      page.find(".op-toast--close").click
    end

    def dismiss_specific_toaster!(message:, type: :success)
      sleep 0.1
      page.find(".op-toast.-#{type}", text: message).find(".op-toast--close").click
    end

    # Clears a toaster if there is one waiting 1 second max, but do not fail if there is none
    def clear_any_toasters
      if has_button?(I18n.t("js.close_popup_title"), wait: 1)
        find_button(I18n.t("js.close_popup_title")).click
      end
    end

    def expect_no_toaster(type: :success, message: nil, wait: 10)
      if type.nil?
        expect(page).to have_no_css(".op-toast", wait:)
      else
        expect(page).to have_no_css(".op-toast.-#{type}", text: message, wait:)
      end
    end
  end
end
