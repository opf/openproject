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

require 'support/pages/page'

module Pages
  class Grid < ::Pages::Page
    def add_widget(row_number, column_number, location, name)
      within_add_widget_modal(row_number, column_number, location) do
        expect(page)
          .to have_content(I18n.t('js.grid.add_widget'))

        page.find('.grid--addable-widget', text: Regexp.new("^#{name}$")).click
      end
    end

    def expect_no_help_mode
      expect(page)
        .to have_no_selector('.toolbar-item .icon-add')
    end

    def expect_unable_to_add_widget(row_number, column_number, location, name = nil)
      if name
        expect_specific_widget_unaddable(row_number, column_number, location, name)
      else
        expect_widget_adding_prohibited_generally(row_number, column_number)
      end
    end

    def expect_add_widget_enterprise_edition_notice(row_number, column_number, location)
      within_add_widget_modal(row_number, column_number, location) do
        expect(page)
          .to have_content(I18n.t('js.grid.add_widget'))

        expect(page)
          .to have_selector('.notification-box.-ee-upsale', text: I18n.t('js.upsale.ee_only'))
      end
    end

    def area_of(row_number, column_number, location = :within)
      real_row, real_column = case location
                              when :within
                                [row_number * 2, column_number * 2]
                              when :row
                                [row_number * 2 - 1, column_number * 2]
                              when :column
                                [row_number * 2, column_number * 2 - 1]
                              end

      ::Components::Grids::GridArea.of(real_row, real_column).area
    end

    private

    def within_add_widget_modal(row_number, column_number, location)
      area = area_of(row_number, column_number, location)
      area.hover
      area.find('.grid--widget-add', visible: :all).click

      within '.op-modal--portal' do
        yield
      end
    end

    def expect_widget_adding_prohibited_generally(row_number = 1, column_number = 1)
      area = area_of(row_number, column_number)
      area.hover

      expect(area)
        .to have_no_selector('.grid--widget-add')
    end

    def expect_specific_widget_unaddable(row_number, column_number, location, name)
      within_add_widget_modal(row_number, column_number, location) do
        expect(page)
          .to have_content(I18n.t('js.grid.add_widget'))

        expect(page)
          .not_to have_selector('.grid--addable-widget', text: Regexp.new("^#{name}$"))
      end
    end
  end
end
