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
  module Projects
    class Index < ::Pages::Page
      def path
        "/projects"
      end

      def expect_listed(*users)
        rows = page.all 'td.username'
        expect(rows.map(&:text)).to eq(users.map(&:login))
      end

      def filter_by_active(value)
        set_filter('active',
                   'Active',
                   'is',
                   [value])

        click_button 'Apply'
      end

      def set_filter(name, human_name, human_operator = nil, values = [])
        select human_name, from: 'add_filter_select'
        selected_filter = page.find("li[filter-name='#{name}']")

        within(selected_filter) do
          select human_operator, from: 'operator'

          return unless values.any?

          case name
          when 'name_and_identifier'
            set_name_and_identifier_filter(values)
          when 'active'
            set_active_filter(values)
          when 'created_at'
            set_created_at_filter(human_operator, values)
          when /cf_[\d]+/
            set_custom_field_filter(selected_filter, human_operator, values)
          end
        end
      end

      def set_active_filter(values)
        if values.size == 1
          select values.first, from: 'value'
        end
      end

      def set_name_and_identifier_filter(values)
        fill_in 'value', with: values.first
      end

      def set_created_at_filter(human_operator, values)
        case human_operator
        when 'on', 'less than days ago', 'more than days ago', 'days ago'
          fill_in 'value', with: values.first
        when 'between'
          fill_in 'from_value', with: values.first
          fill_in 'to_value', with: values.second
        end
      end

      def set_custom_field_filter(selected_filter, human_operator, values)
        if selected_filter[:'filter-type'] == 'list_optional'
          if values.size == 1
            value_select = find('.single-select select[name="value"]')
            value_select.select values.first
          end
        elsif selected_filter[:'filter-type'] == 'date'
          if human_operator == 'on'
            fill_in 'value', with: values.first
          end
        end
      end

      def open_filters
        click_button('Show/hide filters')
      end

      def click_menu_item_of(title, project)
        activate_menu_of(project) do
          click_link title
        end
      end

      def activate_menu_of(project)
        within_row(project) do |row|
          row.hover
          menu = find('ul.project-actions')
          menu.click
          yield menu
        end
      end

      private

      def within_row(project)
        row = page.find('#project-table tr', text: project.name)

        within row do
          yield row
        end
      end
    end
  end
end
