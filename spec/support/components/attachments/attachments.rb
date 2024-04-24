# JavaScript: HTML5 File attachments handling
# requires a (hidden) input file field
module Components
  class Attachments
    include Capybara::DSL
    include Capybara::RSpecMatchers

    ##
    # Drag and Drop the file loaded from path on to the (native) target element
    def drag_and_drop_file(target, path, position = :center, stopover = nil, cancel_drop: false, delay_dragleave: false)
      # Remove any previous input, if any
      page.execute_script <<-JS
        jQuery('#temporary_attachment_files').remove()
      JS

      if stopover.is_a?(Array) && !stopover.all?(String)
        raise ArgumentError, "In case the stopover is an array, it must contain only string selectors."
      end

      element =
        if target.is_a?(String)
          target
        else
          # Use the HTML5 file dropper to create a fake drop event
          scroll_to_element(target)
          target.native
        end

      page.execute_script(
        js_drop_files,
        element,
        "temporary_attachment_files",
        position.to_s,
        stopover,
        cancel_drop,
        delay_dragleave
      )

      attach_file_on_input(path, "temporary_attachment_files")
    end

    ##
    # Attach a file to the hidden file input
    def attach_file_on_input(path, name = "attachment_files")
      page.attach_file(name, path, visible: :all)
    end

    def js_drop_files
      @js_file ||= File.read(File.expand_path("attachments_input.js", __dir__))
    end
  end
end
