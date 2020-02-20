#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Components
  class AttributeHelpTextModal
    include Capybara::DSL
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
      container.find('.attribute-help-text--modal')
    end

    def open!
      container.find(".help-text--for-#{help_text.attribute_name}").click
      expect(page).to have_selector('.attribute-help-text--modal h3', text: help_text.attribute_caption)
    end

    def close!
      within modal_container do
        page.find('.icon-close').click
      end
      expect(page).to have_no_selector('.attribute-help-text--modal h3', text: help_text.attribute_caption)
    end

    def expect_edit(admin:)
      if admin
        expect(page).to have_selector('.help-text--edit-button')
      else
        expect(page).to have_no_selector('.help-text--edit-button')
      end
    end

    def edit_button
      page.find('.help-text--edit-button')
    end
  end
end
