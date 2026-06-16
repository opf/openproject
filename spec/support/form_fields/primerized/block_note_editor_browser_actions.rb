# frozen_string_literal: true

module FormFields
  module Primerized
    # Low-level browser actions for driving the BlockNote editor's
    # contenteditable inside its shadow root. Capybara cannot enter the shadow
    # root for selection, nor does its `send_keys` propagate Delete/Backspace
    # into ProseMirror's editable in this setup, so each helper drops to the
    # Selenium driver: either running JS via `execute_script` or issuing raw
    # keystrokes via the W3C actions API.
    #
    # Sibling to BlockNoteEditorInput (the high-level page object): keep
    # raw-driver concerns here so the page object stays focused on semantic
    # actions like `paste_links` or `attach_file`.
    module BlockNoteEditorBrowserActions
      # Selects a text range inside the first external link in the editor.
      # `start_offset` and `end_offset` follow String-slicing conventions: a
      # non-negative integer is an absolute offset from the start of the
      # link's text node; a negative integer counts back from the end; `nil`
      # maps to the text length. Default arguments select the entire link
      # text.
      def select_text_in_external_link(start_offset: 0, end_offset: nil)
        page.execute_script(<<~JS, start_offset, end_offset)
          const root = document.querySelector('op-block-note').shadowRoot;
          const a = root.querySelector('a[target="_blank"]');
          const textNode = [...a.childNodes].find((n) => n.nodeType === 3);
          const len = textNode.textContent.length;
          const resolve = (v) => (v == null ? len : (v < 0 ? len + v : v));
          const range = document.createRange();
          range.setStart(textNode, resolve(arguments[0]));
          range.setEnd(textNode, resolve(arguments[1]));
          const sel = window.getSelection();
          sel.removeAllRanges();
          sel.addRange(range);
        JS
      end

      # Forward Delete via the W3C actions API; pair with a selection helper.
      def send_forward_delete
        page.driver.browser.action.send_keys(:delete).perform
      end

      # Fires a paste ClipboardEvent on the editor with both HTML and
      # plain-text payloads. Exercises ProseMirror's `transformPasted` path,
      # which behaves differently from typed input.
      def paste_clipboard_into(editor_element, html:, plain:)
        editor_element.click
        page.execute_script(<<~JS, editor_element.native, html, plain)
          const target = arguments[0];
          const dt = new DataTransfer();
          dt.setData('text/html', arguments[1]);
          dt.setData('text/plain', arguments[2]);
          target.dispatchEvent(new ClipboardEvent('paste', {
            clipboardData: dt,
            bubbles: true,
            cancelable: true,
          }));
        JS
      end
    end
  end
end
