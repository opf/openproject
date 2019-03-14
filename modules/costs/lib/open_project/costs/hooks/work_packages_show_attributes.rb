#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

module OpenProject::Costs::Hooks
  class WorkPackagesShowHook < Redmine::Hook::ViewListener
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
