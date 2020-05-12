module Components
  class GlobalSearch
    include Capybara::DSL
    include RSpec::Matchers

    def initialize; end

    def container
      page.find('.top-menu-search--input')
    end

    def selector
      '.top-menu-search--input'
    end

    def input
      container.find 'input'
    end

    def search(query, submit: false)
      input.set ''
      input.hover
      input.click
      input.set query

      if submit
        submit_with_enter
      end
    end

    def submit_with_enter
      input.send_keys :enter
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
        .to have_selector('.global-search--project-scope[title="all_projects"]', wait: 10)
    end

    def expect_in_project_and_subproject_scope_marked
      expect(page)
        .to have_selector('.global-search--project-scope[title="current_project_and_all_descendants"]', wait: 10)
    end

    def expect_scope(text)
      expect(page)
        .to have_selector('.global-search--project-scope', text: text, wait: 10)
    end

    def expect_work_package_marked(wp)
      expect(page)
        .to have_selector('.ng-option-marked', text: "##{wp.id} #{wp.subject}", wait: 10)
    end

    def expect_work_package_option(wp)
      expect(page)
        .to have_selector('.global-search--option', text: "##{wp.id} #{wp.subject}", wait: 10)
    end

    def expect_no_work_package_option(wp)
      expect(page)
        .not_to have_selector('.global-search--option', text: "##{wp.id} #{wp.subject}")
    end

    def click_work_package(wp)
      find_work_package(wp).click
    end

    def find_work_package(wp)
      find_option "##{wp.id} #{wp.subject}"
    end

    def find_option(text)
      page.find('.global-search--option', text: text, wait: 10)
    end

    def cancel
      input.send_keys :escape
    end
  end
end
