# frozen_string_literal: true

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

      # Check that the given tab is shown in the tab bar
      def expect_tab(tab)
        expect(page).to have_test_selector("wp-details-tab-component--tab-#{tab.downcase}")
      end

      # Tab should not be displayed, e.g. because the user lacks the permission
      def expect_no_tab(tab)
        expect(page).not_to have_test_selector("wp-details-tab-component--tab-#{tab.downcase}")
      end
    end
  end
end
