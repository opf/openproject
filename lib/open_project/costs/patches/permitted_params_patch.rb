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

module OpenProject::Costs::Patches::PermittedParamsPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def cost_entry
      params.require(:cost_entry).permit(:comments,
                                         :units,
                                         :overridden_costs,
                                         :spent_on)
    end

    def cost_object
      params.require(:cost_object).permit(:subject,
                                          :description,
                                          :fixed_date,
                                          { new_material_budget_item_attributes: [:units, :cost_type_id, :comments, :budget] },
                                          { new_labor_budget_item_attributes: [:hours, :user_id, :comments, :budget] },
                                          { existing_material_budget_item_attributes: [:units, :cost_type_id, :comments, :budget] },
                                          existing_labor_budget_item_attributes: [:hours, :user_id, :comments, :budget])
    end

    def cost_type
      params.require(:cost_type).permit(:name,
                                        :unit,
                                        :unit_plural,
                                        :default,
                                        { new_rate_attributes: [:valid_from, :rate] },
                                        existing_rate_attributes: [:valid_from, :rate])
    end

    def user_rates
      params.require(:user).permit(new_rate_attributes: [:valid_from, :rate],
                                   existing_rate_attributes: [:valid_from, :rate])
    end
  end
end
