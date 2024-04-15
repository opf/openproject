module Components
  class GlobalSearch
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers

    def container
      page.find(".top-menu-search--input")
    end

    def selector
      ".top-menu-search--input"
    end

    def input
      container.find "input"
    end

    def dropdown
      container.find(".ng-dropdown-panel")
    end

    def click_input
      input.hover
      input.click
    end

    def search(query, submit: false)
      SeleniumHubWaiter.wait
      input.set ""
      click_input
      input.set query

      if submit
        submit_with_enter
      end
    end

    def submit_with_enter
      input.send_keys :enter
      SeleniumHubWaiter.wait
    end

    def expect_open
      expect(page).to have_selector(container)
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
      find_work_package(wp).click
    end

    def find_work_package(wp)
      find_option wp.subject.to_s
    end

    def find_option(text)
      expect(page).to have_css(".global-search--wp-subject", text:, wait: 10)
      find(".global-search--wp-subject", text:)
    end

    def cancel
      input.send_keys :escape
    end
  end
end
