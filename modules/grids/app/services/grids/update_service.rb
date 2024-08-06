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

class Grids::UpdateService < BaseServices::Update
  protected

  def perform(attributes)
    set_type_for_error_message(attributes.delete(:scope))

    super
  end

  def after_perform(service_call)
    model.touch if only_widgets_updated?

    super
  end

  def only_widgets_updated?
    !model.saved_changes? && model.widgets.any?(&:saved_changes?)
  end

  # Changing the scope/type after the grid has been created is prohibited.
  # But we set the value so that an error message can be displayed
  def set_type_for_error_message(scope)
    if scope
      grid_class = ::Grids::Configuration.class_from_scope(scope)
      model.type = grid_class.name
    end
  end
end
