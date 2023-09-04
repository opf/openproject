module Toasts
  module Expectations
    def expect_toast(message:, type: :success)
      if toast_type == :angular
        expect(page).to have_selector(".op-toast.-#{type}", text: message, wait: 20)
      elsif type == :error
        expect(page).to have_selector(".errorExplanation", text: message)
      elsif type == :success
        expect(page).to have_selector(".op-toast.-success", text: message)
      else
        raise NotImplementedError
      end
    end

    def expect_and_dismiss_toaster(message: nil, type: :success)
      expect_toast(type:, message:)
      dismiss_toaster!
      expect_no_toaster(type:, message:)
    end

    def dismiss_toaster!
      page.find('.op-toast--close').click
    end

    def expect_no_toaster(type: :success, message: nil)
      if type.nil?
        expect(page).not_to have_selector(".op-toast")
      else
        expect(page).not_to have_selector(".op-toast.-#{type}", text: message)
      end
    end

    def toast_type
      :angular
    end
  end
end
