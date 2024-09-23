#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module Budgets
  class SetAttributesService < ::BaseServices::SetAttributes
    include Attachments::SetReplacements

    private

    def set_attributes(params)
      set_fixed_date(params)
      unset_items(params)

      super
    end

    def set_default_attributes(_params)
      model.change_by_system do
        model.author = user
      end
    end

    # fixed_date must be set before material_budget_items and labor_budget_items
    def set_fixed_date(params)
      model.fixed_date = params.delete(:fixed_date) || Date.today
    end

    def unset_items(params)
      if params[:existing_material_budget_item_attributes].nil?
        model.existing_material_budget_item_attributes = ({})
      end

      if params[:existing_labor_budget_item_attributes].nil?
        model.existing_labor_budget_item_attributes = ({})
      end
    end
  end
end
