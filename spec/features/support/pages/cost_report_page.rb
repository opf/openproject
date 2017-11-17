module Pages
  class CostReportPage < ::Pages::Page
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def clear
      click_on 'Clear'
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
  end
end