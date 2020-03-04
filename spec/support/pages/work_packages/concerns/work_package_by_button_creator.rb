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

module Pages
  module WorkPackages
    module Concerns
      module WorkPackageByButtonCreator
        def create_wp_by_button(type)
          click_wp_create_button

          find('#types-context-menu .menu-item', text: type.name.upcase, wait: 10).click

          create_page_class_instance(type)
        end

        def click_wp_create_button
          find('.add-work-package:not([disabled])', text: 'Create').click
        end

        def expect_wp_create_button_disabled
          expect(page)
            .to have_selector('.add-work-package[disabled]', text: 'Create')
        end

        def expect_type_available_for_create(type)
          click_wp_create_button

          expect(page)
            .to have_selector('#types-context-menu .menu-item', text: type.name.upcase)
        end

        def expect_type_not_available_for_create(type)
          click_wp_create_button

          expect(page)
            .to have_no_selector('#types-context-menu .menu-item', text: type.name.upcase)
        end

        private

        def create_page_class_instance(_type)
          create_page_class.new(project: project)
        end

        def create_page_class
          raise NotImplementedError
        end
      end
    end
  end
end
