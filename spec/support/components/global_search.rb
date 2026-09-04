# frozen_string_literal: true

module Components
  class GlobalSearch
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include Components::Autocompleter::NgSelectAutocompleteHelpers
    include RSpec::Matchers

    def container
      page.find(selector)
    end

    def selector
      ".global-search"
    end

    def input
      container.find "input"
    end

    def dropdown
      page.find(".ng-dropdown-panel")
    end

    def click_input
      input.hover
      input.click
    end

    def search(query, submit: false)
      if using_cuprite?
        ng_click_autocompleter(method(:container))
        query_input = ng_select_input(container)
        page.execute_script(<<~JS, query_input, query.to_s)
          const input = arguments[0];
          const value = arguments[1];
          const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set;
          setter.call(input, "");
          input.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "deleteContentBackward" }));
          setter.call(input, value);
          input.dispatchEvent(new InputEvent("input", { bubbles: true, data: value, inputType: "insertText" }));
        JS
      else
        SeleniumHubWaiter.wait
        input.set ""
        click_input
        input.set query
      end

      if submit
        submit_with_enter
      end
    end

    def submit_with_enter
      input.send_keys :enter
      SeleniumHubWaiter.wait
    end

    def open_tab(tab_id)
      page.within_test_selector("search-tabs") do
        name = tab_id.is_a?(Symbol) ? OpenProject::GlobalSearch.tab_name(tab_id.to_s) : tab_id
        click_on(name)
      end
    end

    def expect_active_tab(id)
      expect(page).to have_css("#{page.test_selector("search-tab-#{id}")}[aria-current]")
    end

    def expect_open
      expect(page).to have_selector(selector)
    end

    def expect_closed
      expect(page).to have_no_selector("#{selector}.expanded")
    end

    def submit_in_project_and_subproject_scope
      page.find('.global-search--project-scope[title="current_project_and_all_descendants"]', wait: 10).click
    end

    def submit_in_current_project
      page.find('.global-search--project-scope[title="current_project"]', wait: 10).click
    end

    def submit_in_global_scope
      page.find('.global-search--project-scope[title="all_projects"]', wait: 10).click
    end

    def expect_global_scope_marked
      expect(page)
        .to have_css('.global-search--project-scope[title="all_projects"]', wait: 10)
    end

    def expect_in_project_and_subproject_scope_marked
      expect(page)
        .to have_css('.global-search--project-scope[title="current_project_and_all_descendants"]', wait: 10)
    end

    def expect_scope(text)
      expect(page)
        .to have_css(".global-search--project-scope", text:, wait: 10)
    end

    def expect_work_package_marked(wp)
      expect(page)
        .to have_css(".ng-option-marked", text: wp.subject.to_s, wait: 10)
    end

    def expect_work_package_option(wp)
      expect(page)
        .to have_css(".global-search--option", text: wp.subject.to_s, wait: 10)
    end

    def expect_no_work_package_option(wp)
      expect(page)
        .to have_no_css(".global-search--option", text: wp.subject.to_s)
    end

    def click_work_package(wp)
      unless using_cuprite?
        find_work_package(wp).click
        return
      end

      page.document.synchronize do
        clicked = page.evaluate_script(<<~JS, wp.subject.to_s)
          (() => {
            const text = arguments[0];
            const subject = Array.from(document.querySelectorAll(".global-search--wp-subject"))
              .find((element) => element.textContent.trim() === text);
            if (subject) {
              subject.closest("a").click();
              return true;
            }
            return false;
          })()
        JS
        raise Capybara::ElementNotFound unless clicked
      end
    end

    def find_work_package(wp)
      find_option wp.subject.to_s
    end

    def find_option(text)
      find(".global-search--wp-subject", text:, wait: 10)
    end

    def cancel
      input.send_keys :escape
    end
  end
end
