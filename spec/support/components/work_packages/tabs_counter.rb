require 'features/support/components/ui_autocomplete'

module Components
  module WorkPackages
    class Tabs
      include Capybara::DSL
      include RSpec::Matchers
      include ::Components::UIAutocompleteHelpers

      attr_reader :work_package

      def initialize(work_package)
        @work_package = work_package
      end

      # Counter elements
        # 2: Relation tab in split view
        # 3: Relation tab in full view and watchers tab in split view
        # 4: Watchers tab in full view
      def counter_for(tabindex)
        find('ul.tabrow > li:nth-child(' + tabindex.to_s + ') .wp-tabs-count')
      end

      # Check number of relations or watchers for tab with given index
      def expect_counter(tabindex, content)
        expect(counter_for(tabindex)).to have_content(content.to_s)
      end

      # There are no relations or watchers
      def expect_no_counter()
        expect(page).to have_no_selector('.wp-tabs-count')
      end
    end
  end
end
