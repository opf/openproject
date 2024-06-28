# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

module Queries::AttributeSetting
  private

  def set_attributes(params)
    set_filters(params.delete(:filters))
    set_order(params.delete(:orders))
    set_select(params.delete(:selects))

    if model.is_a?(ApplicationRecord)
      super
    else
      set_default_attributes(params)
    end
  end

  def set_default_attributes(_params)
    set_default_user if model.is_a?(ApplicationRecord)
    set_default_filter if model.filters.empty?
    set_default_order if model.orders.empty?
    set_default_selects if model.selects.empty?
  end

  def set_default_user
    model.change_by_system do
      model.user = user
    end
  end

  def set_default_order
    # Nothing or now but overwritable by including class
  end

  def set_default_filter
    # Nothing or now but overwritable by including class
  end

  def set_default_selects
    # Nothing or now but overwritable by including class
  end

  def set_filters(filters)
    return unless filters

    model.filters.clear
    filters.each do |filter|
      model.where(filter[:attribute], filter[:operator], filter[:values])
    end
  end

  def set_order(orders)
    return unless orders

    model.orders.clear
    model.order(orders.to_h { |o| [o[:attribute], o[:direction]] })
  end

  def set_select(selects)
    return unless selects

    model.selects.clear
    model.select(*selects)
  end
end
