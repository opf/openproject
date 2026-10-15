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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  module Settings
    module WorkPackagesGeneral
      class DefaultColumnsComponent < ApplicationComponent
        def call
          helpers.angular_component_tag "opce-draggable-autocompleter",
                                        inputs: {
                                          autofocus: false,
                                          options: helpers.work_packages_columns_options,
                                          selected: helpers.selected_work_packages_columns_options,
                                          protected: helpers.protected_work_packages_columns_options,
                                          name: "settings[work_package_list_default_columns][]",
                                          id: "setting_column_options",
                                          inputLabel: I18n.t(:"queries.configure_view.columns.input_label"),
                                          inputPlaceholder: I18n.t(:"queries.configure_view.columns.input_placeholder"),
                                          dragAreaLabel: I18n.t(:"queries.configure_view.columns.drag_area_label")
                                        }
        end
      end
    end
  end
end
