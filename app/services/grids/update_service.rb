#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

class Grids::UpdateService
  include ::Shared::ServiceContext

  attr_accessor :user,
                :grid,
                :contract_class

  def initialize(user:, grid:, contract_class: Grids::UpdateContract)
    self.user = user
    self.grid = grid
    self.contract_class = contract_class
  end

  def call(attributes: {})
    in_context(false) do
      create(attributes)
    end
  end

  protected

  def create(attributes)
    set_type_for_error_message(attributes.delete(:page))

    set_attributes_call = set_attributes(attributes, grid)

    if set_attributes_call.success? &&
       !grid.save
      set_attributes_call.errors = grid.errors
      set_attributes_call.success = false
    end

    set_attributes_call
  end

  def set_attributes(attributes, grid)
    Grids::SetAttributesService
      .new(user: user,
           grid: grid,
           contract_class: contract_class)
      .call(attributes)
  end

  # Changing the page/type after the grid has been created is prohibited.
  # But we set the value so that an error message can be displayed
  def set_type_for_error_message(page)
    if page
      grid_class = ::Grids::Configuration.grid_for_page(page)
      grid.type = grid_class.name
    end
  end
end
