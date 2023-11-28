#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module OpPrimer
  module ComponentHelpers
    def flex_layout(**, &)
      render(Primer::OpenProject::FlexLayout.new(**), &)
    end

    def grid_layout(css_class, **, &)
      render(Primer::OpenProject::GridLayout.new(css_class:, **), &)
    end

    def box_collection(**, &)
      render(OpPrimer::BoxCollectionComponent.new(**), &)
    end

    def component_collection(**, &)
      render(OpPrimer::ComponentCollectionComponent.new(**), &)
    end

    # There is currently no available system argument for setting an id on the
    # rendered <ul> tag that houses the row slots on Primer::Beta::BorderBox components.
    # Setting an id is required to be able to uniquely identify a target for
    # TurboStream +insert+ actions and being able to prepend and append to it.
    def border_box_with_id(id, **, &)
      border_box = Primer::Beta::BorderBox.new(**)

      new_list_arguments = border_box.instance_variable_get(:@list_arguments)
                                     .merge(id:)

      border_box.instance_variable_set(:@list_arguments, new_list_arguments)

      render(border_box, &)
    end

    def border_box_row(wrapper_arguments, &)
      if container
        container.with_row(**wrapper_arguments, &)
      else
        container = Primer::Beta::BorderBox.new
        row = container.registered_slots[:rows][:renderable_function]
                       .bind_call(container, **wrapper_arguments)

        render(row, &)
      end
    end
  end
end
