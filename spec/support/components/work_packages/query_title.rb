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
  module WorkPackages
    class QueryTitle
      include Capybara::DSL
      include RSpec::Matchers


      def expect_changed
        expect(page).to have_selector '.editable-toolbar-title--save'
        expect(page).to have_selector '.editable-toolbar-title--input.-changed'
      end

      def expect_not_changed
        expect(page).to have_no_selector '.editable-toolbar-title--save'
        expect(page).to have_no_selector '.editable-toolbar-title--input.-changed'
      end

      def input_field
        find('.editable-toolbar-title--input')
      end

      def expect_title(name)
        expect(page).to have_field('editable-toolbar-title', with: name)
      end

      def press_save_button
        find('.editable-toolbar-title--save').click
      end

      def rename(name, save: true)
        fill_in 'editable-toolbar-title', with: name

        if save
          input_field.send_keys :return
        end
      end
    end
  end
end
