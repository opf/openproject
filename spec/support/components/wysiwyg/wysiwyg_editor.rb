module Components
  class WysiwygEditor
    include Capybara::DSL
    include RSpec::Matchers
    attr_reader :context_selector, :attachments


    def initialize(context = '#content')
      @context_selector = context
      @attachments = ::Components::Attachments.new
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

    def set_markdown(text)
      textarea = container.find('.op-ckeditor-source-element', visible: :all)
      page.execute_script(
        'jQuery(arguments[0]).trigger("op:ckeditor:setData", arguments[1])',
        textarea.native,
        text
      )
    end

    def clear
      textarea = container.find('.op-ckeditor-source-element', visible: :all)
      page.execute_script(
        'jQuery(arguments[0]).trigger("op:ckeditor:clear")',
        textarea.native
      )
    end

    def expect_button(label)
      expect(container).to have_selector('.ck-button', visible: :all, text: label)
    end

    def expect_no_button(label)
      expect(container).to have_no_selector('.ck-button', visible: :all, text: label)
    end

    def expect_value(value)
      expect(editor_element.text).to eq(value)
    end

    def within_enabled_preview
      click_toolbar_button 'Toggle preview mode'
      begin
        yield container.find('.ck-editor__preview')
      ensure
        click_toolbar_button 'Toggle preview mode'
      end
    end

    ##
    # Create an image fixture with the optional caption
    # Note: The caption will be added to all figures
    def drag_attachment(image_fixture, caption = 'Some caption')
      in_editor do |container, editable|
        sleep 0.5
        refocus
        editable.base.send_keys(:enter, 'some text', :enter, :enter)
        sleep 0.5

        images = editable.all('figure.image')
        attachments.drag_and_drop_file(editable, image_fixture)

        expect(page)
          .to have_selector('figure img[src^="/api/v3/attachments/"]', count: images.length + 1, wait: 10)

        expect(page).not_to have_selector('notification-upload-progress')
        refocus
        sleep 0.5
        # Besides testing caption functionality this also slows down clicking on the submit button
        # so that the image is properly embedded
        editable.all('figure').each do |figure|

          # Locate image within figure
          # Click on image to show figcaption
          img = figure.find('img')
          img.click
          sleep 0.5

          # Locate figcaption to create comment
          figcaption = figure.find('figcaption')
          figcaption.click
          figcaption.send_keys(caption)
          sleep 0.5
        end
      end
    end

    def refocus
      editor_element.first('*').click
    rescue => e
      warn "Failed to refocus on first editor element #{e}"
    end

    def click_toolbar_button(label)
      # strangely, we need visible: :all here
      container.find('.ck-button', visible: :all, text: label).click
    end

    def click_and_type_slowly(*text)
      sleep 0.5
      editor_element.click

      sleep 0.5
      editor_element.send_keys *text

      sleep 0.5
    end

    def click_hover_toolbar_button(label)
      page.find('.ck-toolbar .ck-button', text: label, visible: :all).click
    end

    def insert_macro(label)
      container.find('.ck-button', visible: :all, text: 'Macros').click
      container.find('.ck-button', visible: :all, text: label).click
    end
  end
end
