module Pages
  class CostReportPage < ::Pages::Page
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def clear
      # We often clear the page as the first action of the example,
      # which is why the frontend might not be fully initialized
      retry_block do
        scroll_to_and_click(find('#query-link-clear', text: 'Clear'))

        # Safeguard to force waiting for the form to be cleared
        expect(page)
          .not_to have_selector('.group-by--selected-element')
      end
    end

    def save(as:, public: false)
      # Scroll to report bottom and click
      scroll_to_and_click(find('#query-icon-save-as', text: 'Save'))

      # Ensure the form is visible
      scroll_to_element find('#save_as_form')

      page.within('#save_as_form') do
        fill_in 'Name', with: as

        if public
          check 'Public'
        end

        click_on 'Save'
      end
    end

    def switch_to_type(label)
      choose label
      apply
    end

    def remove_row_element(text)
      element_name = find("#group-by--rows label", text: text)[:for]
      find("##{element_name}_remove").click
    end

    def remove_column_element(text)
      element_name = find("#group-by--columns label", text: text)[:for]
      find("##{element_name}_remove").click
    end

    def apply
      scroll_to_and_click(find("[id='query-icon-apply-button']"))
    end

    def add_to_rows(name)
      select name, from: 'group-by--add-rows'
    end

    def add_to_columns(name)
      select name, from: 'group-by--add-columns'
    end

    def expect_row_element(text, present: true)
      if present
        expect(page).to have_selector('#group-by--selected-rows .group-by--selected-element', text: text)
      else
        expect(page).to have_no_selector('#group-by--selected-rows .group-by--selected-element', text: text)
      end
    end

    def expect_column_element(text, present: true)
      if present
        expect(page).to have_selector('#group-by--selected-columns .group-by--selected-element', text: text)
      else
        expect(page).to have_no_selector('#group-by--selected-columns .group-by--selected-element', text: text)
      end
    end

    def show_loading_indicator(present: true)
      if present
        expect(page).to have_selector('#ajax-indicator')
      else
        expect(page).to have_no_selector('#ajax-indicator')
      end
    end

    def path
      cost_reports_path(project)
    end
  end
end
