# frozen_string_literal: true

# Handles attachments list generally found under the wysiwyg editor.
module Components
  class AttachmentsList
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers

    attr_reader :context_selector

    def initialize(context = "#content")
      @context_selector = context
    end

    # Simulates start dragging a file into the window by sending a "dragenter" event.
    def drag_enter
      wait_until_visible # element must be visible before any drag and drop
      page.execute_script <<~JS
        const event = new DragEvent('dragenter');
        document.body.dispatchEvent(event);
      JS
    end

    # Drops a file into the attachments list drop box.
    def drop(file)
      path = file.to_s
      drop_box_element.drop(path)
    end

    def delete(file_name)
      item = find("#{context_selector} [data-test-selector='op-attachment-list-item']", text: file_name)
      item.hover
      item.find(:button, title: I18n.t("js.label_remove_file", fileName: file_name)).click
      # confirm delete confirmation dialog
      expect(page).to have_content(I18n.t("js.attachments.delete_confirmation"))
      find(:button, text: I18n.t("js.attachments.delete")).click
    end

    def expect_empty
      expect(page).to have_no_css("#{context_selector} [data-test-selector='op-attachment-list-item']")
    end

    def expect_attached(name, count: 1)
      expect(page).to have_css("#{context_selector} [data-test-selector='op-attachment-list-item']", text: name, count:, wait: 20)
    end

    def expect_attached!(name, count: 1)
      unless page.has_css?("#{context_selector} [data-test-selector='op-attachment-list-item']", text: name, count:)
        raise "Expected to have #{name} attached with a count of #{count}"
      end
    end

    def wait_until_visible
      element.tap { scroll_to_element(it) }
    end

    def element
      page.find("#{context_selector} [data-test-selector='op-attachments']")
    end

    def drop_box_element
      find("#{context_selector} [data-test-selector='op-attachments--drop-box']")
    end
  end
end
