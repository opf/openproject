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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Components
  class AttributeHelpTextModal
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers

    attr_reader :help_text, :context

    def initialize(help_text, context: nil)
      @context = context
      @help_text = help_text
    end

    def container
      if context
        page.find(context)
      else
        page
      end
    end

    def modal_container
      container.find(".attribute-help-text--modal")
    end

    def open!
      SeleniumHubWaiter.wait
      container.find("[data-qa-help-text-for='#{help_text.attribute_name.camelize(:lower)}']").click
      expect(page).to have_css('[data-test-selector="attribute-help-text--header"]', text: help_text.attribute_caption)
    end

    def close!
      # make backdrop click an the pixel x:10,y:10
      page.find(".spot-modal-overlay").tap do |element|
        if RSpec.current_example.metadata[:with_cuprite]
          width = element.style("width")["width"].to_i
          height = element.style("height")["height"].to_i
        else
          width = element.native.size.width
          height = element.native.size.height
        end
        element.click(x: -((width / 2) - 10), y: -((height / 2) - 10))
      end
      expect(page).to have_no_css('[data-test-selector="attribute-help-text--header"]', text: help_text.attribute_caption)
    end

    def expect_edit(editable:)
      if editable
        expect(page).to have_css(".help-text--edit-button")
      else
        expect(page).to have_no_css(".help-text--edit-button")
      end
    end

    def edit_button
      page.find(".help-text--edit-button")
    end
  end
end
