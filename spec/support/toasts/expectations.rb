module Toasts
  module Expectations
    def expect_toast(message:, type: :success, wait: 20)
      if toast_type == :angular
        expect(page).to have_css(".op-toast.-#{type}", text: message, wait:)
      elsif type == :error
        expect(page).to have_css(".errorExplanation", text: message)
      elsif type == :success
        expect(page).to have_css(".op-toast.-success", text: message)
      else
        raise NotImplementedError
      end
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

    def expect_no_toaster(type: :success, message: nil, wait: 10)
      if type.nil?
        expect(page).to have_no_css(".op-toast", wait:)
      else
        expect(page).to have_no_css(".op-toast.-#{type}", text: message, wait:)
      end
    end

    def toast_type
      :angular
    end
  end
end
