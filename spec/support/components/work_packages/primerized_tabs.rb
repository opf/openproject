module Components
  module WorkPackages
    class PrimerizedTabs
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      # Check value of counter for the given tab
      def expect_counter(tab, count)
        expect(page).to have_test_selector("wp-details-tab-component--#{tab}-counter", text: count)
      end

      # Counter should not be displayed, if there are no relations or watchers
      def expect_no_counter(tab)
        expect(page).not_to have_test_selector("wp-details-tab-component--#{tab}-counter")
      end
    end
  end
end
