# JavaScript: HTML5 File attachments handling
# requires a (hidden) input file field
module Components
  class Attachments
    include Capybara::DSL

    def initialize; end

    ##
    # Drag and Drop the file loaded from path on to the (native) target element
    def drag_and_drop_file(target, path)
      # Remove any previous input, if any
      page.execute_script <<-JS
        jQuery('#temporary_attachment_files').remove()
      JS

      # Use the HTML5 file dropper to create a fake drop event
      scroll_to_element(target)
      page.execute_script(js_drop_files, target.native, 'temporary_attachment_files')

      attach_file_on_input(path, 'temporary_attachment_files')
    end

    ##
    # Attach a file to the hidden file input
    def attach_file_on_input(path, name = 'attachment_files')
      page.attach_file(name, path, visible: :all)
    end

    def js_drop_files
      @js_file ||= File.read(File.expand_path('../attachments_input.js', __FILE__))
    end
  end
end
