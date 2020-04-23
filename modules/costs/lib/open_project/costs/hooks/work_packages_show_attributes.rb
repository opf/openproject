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

module OpenProject::Costs::Hooks
  class WorkPackagesShowAttributes < Redmine::Hook::ViewListener
    include ActionView::Context
    include WorkPackagesHelper

    def work_packages_show_attributes(context = {})
      @work_package = context[:work_package]
      @project = context[:project]
      attributes = context[:attributes]

      return unless @project.module_enabled? :costs_module

      attributes << cost_work_package_attributes
      attributes.flatten!

      attributes
    end

    private

    def cost_work_package_attributes
      attributes = []

      attributes_helper = OpenProject::Costs::AttributesHelper.new(@work_package)

      attributes << work_package_show_table_row(:cost_object) {
        @work_package.cost_object ?
          link_to_cost_object(@work_package.cost_object) :
          empty_element_tag
      }

      attributes << work_package_show_table_row(:overall_costs) {
        attributes_helper.overall_costs ?
          number_to_currency(attributes_helper.overall_costs) :
          empty_element_tag
      }

      if attributes_helper.summarized_cost_entries
        attributes << work_package_show_table_row(:spent_units) {
          summarized_cost_entry_links(attributes_helper.summarized_cost_entries, @work_package)
        }
      end

      attributes
    end

    def summarized_cost_entry_links(cost_entries, work_package, create_link = true)
      str_array = []
      cost_entries.each do |cost_type, units|
        txt = pluralize(units, cost_type.unit, cost_type.unit_plural)
        if create_link
          # TODO why does this have project_id, work_package_id and cost_type_id params?
          str_array << link_to(txt, { controller: '/cost_reports',
                                      action: 'index',
                                      project_id: work_package.project_id,
                                      cost_type_id: cost_type },
                               title: cost_type.name)
        else
          str_array << "<span title=\"#{h(cost_type.name)}\">#{txt}</span>"
        end
      end
      str_array.join(', ').html_safe
    end
  end
end
