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
