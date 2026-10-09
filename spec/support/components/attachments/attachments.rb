# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# JavaScript: HTML5 File attachments handling
# requires a (hidden) input file field
module Components
  class Attachments
    include Capybara::DSL
    include Capybara::RSpecMatchers

    ##
    # Drag and Drop the file loaded from path on to the (native) target element
    def drag_and_drop_file(target,
                           path,
                           position = :center,
                           stopover = nil,
                           cancel_drop: false,
                           delay_dragleave: false,
                           scroll: true)
      # Remove any previous input, if any
      page.execute_script <<-JS
        document.getElementById('temporary_attachment_files')?.remove()
      JS

      if stopover.is_a?(Array) && !stopover.all?(String)
        raise ArgumentError, "In case the stopover is an array, it must contain only string selectors."
      end

      element =
        if target.is_a?(String)
          target
        else
          # Use the HTML5 file dropper to create a fake drop event
          scroll_to_element(target) if scroll
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
