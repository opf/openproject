# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  module Settings
    class ColumnSelectionComponent < ApplicationComponent
      def initialize(name:, columns:, selected:, protected:)
        super()
        @name = name
        @columns = columns
        @selected = selected
        @protected = protected
      end

      attr_reader :name, :columns, :selected, :protected

      def call
        helpers.angular_component_tag(
          "opce-draggable-autocompleter",
          data: { setting_name: name },
          inputs: {
            autofocus: false,
            options: columns,
            selected:,
            protected:,
            name: helpers.field_name(:settings, name, multiple: true),
            id: helpers.field_id(:settings, name),
            inputLabel: I18n.t(:"queries.configure_view.columns.input_label"),
            inputPlaceholder: I18n.t(:"queries.configure_view.columns.input_placeholder"),
            dragAreaLabel: I18n.t(:"queries.configure_view.columns.drag_area_label")
          }
        )
      end
    end
  end
end
