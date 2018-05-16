# JavaScript: HTML5 File drop
# Author: florentbr
# source            : https://gist.github.com/florentbr/0eff8b785e85e93ecc3ce500169bd676
# param1 WebElement : Drop area element (Target of the drop)
# param2 String     : Optional - ID / Name of the temporary field (use when addressing the field without send_keys)
# param3 Double     : Optional - Drop offset x relative to the top/left corner of the drop area. Center if 0.
# param4 Double     : Optional - Drop offset y relative to the top/left corner of the drop area. Center if 0.

module Components
  class AttachmentsDropper
    include Capybara::DSL

    def initialize; end

    ##
    # Drag and Drop the file loaded from path on to the (native) target element
    def drag_and_drop_file(target, path)
      # Remove any previous input, if any
      page.execute_script <<-JS
        jQuery('#temporaryFileInput').remove()
      JS

      # Use the HTML5 file dropper to create a fake drop event
      page.execute_script(js_drop_files, target, 'temporaryFileInput', 0, 0)
      page.attach_file("temporaryFileInput", path, visible: :all)
    end

    def js_drop_files
      @js_file ||= File.read(File.expand_path('../attachments_input.js', __FILE__))
    end
  end
end
