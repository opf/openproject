module Components
  class WysiwygEditor
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers

    attr_reader :context_selector, :attachments, :attachments_list

    def initialize(context = "#content", attachment_list_selector = "opce-ckeditor-augmented-textarea")
      @context_selector = context
      @attachments = ::Components::Attachments.new
      @attachments_list = ::Components::AttachmentsList.new("#{context} #{attachment_list_selector}")
    end

    def container
      page.find("#{context_selector} .op-ckeditor--wrapper", wait: 10)
    end

    def editor_element
      page.find("#{context_selector} #{input_selector}", wait: 10)
    end

    def in_editor
      yield container, editor_element
    end

    def input_selector
      "div.ck-content"
    end

    def set_markdown(text)
      wait_until_loaded

      textarea = container.find(".op-ckeditor-source-element", visible: :all)
      page.execute_script(
        'jQuery(arguments[0]).trigger("op:ckeditor:setData", arguments[1])',
        textarea.native,
        text
      )
    end

    def clear
      textarea = container.find(".op-ckeditor-source-element", visible: :all)
      page.execute_script(
        'jQuery(arguments[0]).trigger("op:ckeditor:clear")',
        textarea.native
      )
    end

    def trigger_autosave
      textarea = container.find(".op-ckeditor-source-element", visible: :all)
      page.execute_script(
        'jQuery(arguments[0]).trigger("op:ckeditor:autosave")',
        textarea.native
      )
    end

    def expect_button(label)
      expect(container).to have_css(".ck-button", visible: :all, text: label)
    end

    def expect_no_button(label)
      expect(container).to have_no_css(".ck-button", visible: :all, text: label)
    end

    def expect_value(value)
      expect(editor_element.text).to eq(value)
    end

    def expect_supports_macros
      expect(container)
          .to have_css(".ck-button", visible: :all, text: "Macros")
    end

    def within_enabled_preview
      click_toolbar_button "Toggle preview mode"
      begin
        yield container.find(".ck-editor__preview")
      ensure
        click_toolbar_button "Toggle preview mode"
      end
    end

    ##
    # Create an image fixture with the optional caption from inside the ckeditor
    def drag_attachment(image_fixture, caption = "Some caption")
      in_editor do |_container, editable|
        # Click the latest figure, if any
        # Do not wait more than 1 second to check if there is an image
        images = editable.all("figure.image", wait: 1)
        if images.count > 0
          images.last.click

          # Click the "move below figure" button
          selected = page.all(".ck-widget_selected .ck-widget__type-around__button_after")
          selected.first&.click
        end

        editable.base.send_keys(:enter, "some text", :enter, :enter)

        attachments.drag_and_drop_file(editable, image_fixture, :bottom)

        expect(page)
            .to have_css('img[src^="/api/v3/attachments/"]', count: images.length + 1, wait: 10)

        wait_until_upload_progress_toaster_cleared

        # Get the image uploaded last. As there is no way to distinguish between
        # two uploaded images, from the perspective of the user, we do it by getting
        # the id of the attachment uploaded last.
        last_id = Attachment.last.id
        image = find("img[src^=\"/api/v3/attachments/#{last_id}\"]")
        # Besides testing caption functionality this also slows down clicking on the submit button
        # so that the image is properly embedded
        figure = image.find(:xpath, "../..")

        retry_block do
          # Toggle caption with button since newer version of ckeditor
          click_hover_toolbar_button "Toggle caption on"

          # Locate figcaption to create comment
          @figure_find = figure.find("figcaption")
          figcaption = @figure_find
          figcaption.click
          sleep(0.2)
          figcaption.send_keys(caption)

          # Expect caption set
          figure.find("figcaption", text: caption)
        end
      end
    end

    def wait_until_upload_progress_toaster_cleared
      page.has_no_selector?("op-toasters-upload-progress")
    end

    def wait_until_loaded
      editor_element
    end

    def refocus
      editor_element.first("*").click
    rescue StandardError => e
      warn "Failed to refocus on first editor element #{e}"
    end

    def insert_link(link)
      click_toolbar_button "Link"
      page.find(".ck-input-text").set link
      page.find(".ck-button-save").click
    end

    def click_toolbar_button(label)
      # strangely, we need visible: :all here
      container.find(".ck-button", visible: :all, text: label).click
    end

    def type_slowly(*)
      editor_element.send_keys(*)
      sleep 0.2
    end

    def click_and_type_slowly(*)
      sleep 0.2
      editor_element.click

      sleep 0.2
      type_slowly(*)
    end

    def click_hover_toolbar_button(label)
      page.find(".ck-toolbar .ck-button", text: label, visible: :all).click
    end

    def insert_macro(label)
      container.find(".ck-button", visible: :all, text: "Macros").click
      container.find(".ck-button", visible: :all, text: label).click
    end

    def click_autocomplete(text)
      page.find(".mention-list-item", text:).click
    end

    def align_table_by_label(editor, table, label)
      # Style first td in table
      table
          .find(".op-uc-table--row:first-of-type .op-uc-table--cell:first-of-type")
          .click

      # Click table toolbar
      editor.click_hover_toolbar_button "Table properties"

      # Set alignment left
      editor.click_hover_toolbar_button label

      find(".ck-button-save").click
    end
  end
end
