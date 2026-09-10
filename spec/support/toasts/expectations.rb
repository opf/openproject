# frozen_string_literal: true

module Toasts
  module Expectations
    def expect_toast(message:, type: :success, wait: 20)
      expect(page).to have_css(".op-toast.-#{type}", text: message, wait:)
    end

    def expect_and_dismiss_toaster(message: nil, type: :success, wait: 20)
      expect_toast(type:, message:, wait:)
      dismiss_toaster!
      expect_no_toaster(type:, message:, wait:)
    end

    # Like #expect_and_dismiss_toaster, but tolerant of a single user action raising
    # several identical toasts (e.g. a grid change that persists in multiple steps).
    # Dismisses every matching toast, allowing late ones to still appear, before
    # asserting that none remain.
    def expect_and_dismiss_all_toasters(message: nil, type: :success, wait: 20)
      expect_toast(type:, message:, wait:)
      wait_for_network_idle(duration: 1) if using_cuprite?

      while page.has_css?(".op-toast.-#{type}", wait: 1)
        page.document.synchronize do
          page.first(".op-toast.-#{type} .op-toast--close", wait: 0)&.click
        end
      end

      expect_no_toaster(type:, message:, wait: 2)
    end

    def dismiss_toaster!
      # Toasts can auto-dismiss between the presence assertion and this click.
      # Clicking the current DOM node in the browser makes that disappearance a
      # successful dismissal instead of retaining an obsolete Capybara node.
      page.execute_script("document.querySelector('.op-toast--close')?.click()")
    end

    def dismiss_specific_toaster!(message:, type: :success)
      page.document.synchronize do
        page.find(".op-toast.-#{type}", text: message).find(".op-toast--close").click
      end
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
