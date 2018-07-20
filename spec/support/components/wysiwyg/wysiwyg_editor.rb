module Components
  class WysiwygEditor
    include Capybara::DSL
    attr_reader :context_selector

    def initialize(context = '#content')
      @context_selector = context
    end

    def container
      page.find("#{context_selector} .op-ckeditor--wrapper")
    end

    def editor_element
      page.find "#{context_selector} #{input_selector}"
    end

    def in_editor
      yield container, editor_element
    end

    def input_selector
      'div.ck-content'
    end

    def expect_value(value)
      expect(input_element.text).to eq(value)
    end

    def click_toolbar_button(label)
      # strangely, we need visible: :all here
      container.find('.ck-button', visible: :all, text: label).click
    end

    def click_and_type_slowly(text)
      sleep 0.5
      input_element.click

      sleep 0.5
      input_element.send_keys text

      sleep 0.5
    end

    def insert_macro(label)
      container.find('.ck-button', visible: :all, text: 'Macros').click
      container.find('.ck-button', visible: :all, text: label).click
    end
  end
end
