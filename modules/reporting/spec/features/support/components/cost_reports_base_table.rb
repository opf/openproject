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
  class CostReportsBaseTable
    include Capybara::DSL
    include RSpec::Matchers

    attr_reader :time_logging_modal

    def initialize
      @time_logging_modal = Components::TimeLoggingModal.new
    end

    def rows_count(count)
      expect(page).to have_selector('#result-table tbody tr', count: count)
    end

    def expect_action_icon(icon, row, present: true)
      if present
        expect(page).to have_selector("#{row_selector(row)} .icon-#{icon}")
      else
        expect(page).to have_no_selector("#{row_selector(row)} .icon-#{icon}")
      end
    end

    def expect_value(value, row)
      expect(page).to have_selector("#{row_selector(row)} .units", text: value)
    end

    def edit_time_entry(new_value, row)
      page.find("#{row_selector(row)} .icon-edit").click

      time_logging_modal.is_visible true
      time_logging_modal.update_field 'hours', new_value
      time_logging_modal.work_package_is_missing false

      time_logging_modal.perform_action 'Save'

      sleep(3)

      expect_action_icon 'edit', row
      expect_value new_value, row
    end

    def edit_cost_entry(new_value, row, cost_entry_id)
      page.find("#{row_selector(row)} .icon-edit").click

      expect(page).to have_current_path('/cost_entries/' + cost_entry_id + '/edit')

      fill_in('cost_entry_units', with: new_value)
      click_button 'Save'
      expect(page).to have_selector('.flash.notice')

      sleep(3)
    end

    def delete_entry(row)
      page.find("#{row_selector(row)} .icon-delete").click

      page.driver.browser.switch_to.alert.accept

      sleep(3)
    end

    private

    def row_selector(row)
      "#result-table tbody tr:nth-of-type(#{row})"
    end
  end
end
