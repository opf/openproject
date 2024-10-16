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

    def dismiss_toaster!
      sleep 0.1
      page.find(".op-toast--close").click
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
