#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/page'

module Pages
  class NewBudget < Page
    attr_reader :project_identifier

    def initialize(project_identifier)
      @project_identifier = project_identifier
    end

    def path
      "/projects/#{project_identifier}/cost_objects/new"
    end

    ##
    # Adds planned unit costs with the default cost type.
    def add_unit_costs!(num_units, comment: nil)
      fill_in "#{unit_cost_attr_id}_#{unit_rows}_units", with: num_units
      fill_in "#{unit_cost_attr_id}_#{unit_rows}_comments", with: comment if comment.present?

      add_unit_costs_row!
    end

    ##
    # Adds planned labor costs with the default cost type.
    def add_labor_costs!(num_hours, user_name:, comment: nil)
      fill_in "#{labor_cost_attr_id}_#{labor_rows}_hours", with: num_hours
      select user_name, from: "#{labor_cost_attr_id}_#{labor_rows}_user_id"
      fill_in "#{labor_cost_attr_id}_#{labor_rows}_comments", with: comment if comment.present?

      add_labor_costs_row!
    end

    def add_unit_costs_row!
      link = find('#material_budget_items_fieldset a', text: 'Add planned costs')
      link.native.send_keys :return

      @unit_rows = unit_rows + 1
    end

    def add_labor_costs_row!
      link = find('#labor_budget_items_fieldset a', text: 'Add planned costs')
      link.native.send_keys :return

      @labor_rows = labor_rows + 1
    end

    def unit_costs_at(num_row)
      unit_costs_container.all('tbody td.currency')[num_row - 1]
    end

    def overall_unit_costs
      unit_costs_container.first('tfoot td.currency')
    end

    def labor_costs_at(num_row)
      labor_costs_container.all('tbody td.currency')[num_row - 1]
    end

    def overall_labor_costs
      labor_costs_container.first('tfoot td.currency')
    end

    def unit_costs_container
      find_container('Planned unit costs')
    end

    def labor_costs_container
      find_container('Planned labor costs')
    end

    def find_container(title)
      find('h4', text: title).find(:xpath, '..')
    end

    def toggle_unit_costs!
      find('fieldset', text: 'UNITS').click
    end

    def toggle_labor_costs!
      find('fieldset', text: 'LABOR').click
    end

    def unit_cost_attr_id
      'cost_object_new_material_budget_item_attributes'
    end

    def labor_cost_attr_id
      'cost_object_new_labor_budget_item_attributes'
    end

    def unit_rows
      @unit_rows ||= 0
    end

    def labor_rows
      @labor_rows ||= 0
    end
  end
end
