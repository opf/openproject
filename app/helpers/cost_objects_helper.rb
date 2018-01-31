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

require 'csv'

module CostObjectsHelper
  include ApplicationHelper
  include ActionView::Helpers::NumberHelper

  # Check if the current user is allowed to manage the budget.  Based on Role
  # permissions.
  def allowed_management?
    User.current.allowed_to?(:edit_cost_objects, @project)
  end

  def cost_objects_to_csv(cost_objects)
    CSV.generate(col_sep: t(:general_csv_separator)) do |csv|
      # csv header fields
      headers = ['#',
                 Project.model_name.human,
                 CostObject.human_attribute_name(:subject),
                 CostObject.human_attribute_name(:author),
                 CostObject.human_attribute_name(:fixed_date),
                 VariableCostObject.human_attribute_name(:material_budget),
                 VariableCostObject.human_attribute_name(:labor_budget),
                 CostObject.human_attribute_name(:spent),
                 CostObject.human_attribute_name(:created_on),
                 CostObject.human_attribute_name(:updated_on),
                 CostObject.human_attribute_name(:description)
                ]
      csv << headers.map { |c| begin; c.to_s.encode('UTF-8'); rescue; c.to_s; end }
      # csv lines
      cost_objects.each do |cost_object|
        fields = [cost_object.id,
                  cost_object.project.name,
                  cost_object.subject,
                  cost_object.author.name,
                  format_date(cost_object.fixed_date),
                  cost_object.kind == 'VariableCostObject' ? number_to_currency(cost_object.material_budget) : '',
                  cost_object.kind == 'VariableCostObject' ? number_to_currency(cost_object.labor_budget) : '',
                  cost_object.kind == 'VariableCostObject' ? number_to_currency(cost_object.spent) : '',
                  format_time(cost_object.created_on),
                  format_time(cost_object.updated_on),
                  cost_object.description
                 ]
        csv << fields.map { |c| begin; c.to_s.encode('UTF-8'); rescue; c.to_s; end }
      end
    end
  end
end
