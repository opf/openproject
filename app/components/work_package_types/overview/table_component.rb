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

module WorkPackageTypes
  module Overview
    class TableComponent < OpPrimer::BorderBoxTableComponent
      columns :setting, :configuration_mode, :dependents
      # No cell may truncate: a source variant's composite name and the dependents count both
      # have to stay readable.
      main_column :setting, :configuration_mode, :dependents
      mobile_labels :configuration_mode, :dependents

      def initialize(variant:, tabs:)
        super(rows: tabs.reject { |tab| tab[:name] == ::TypesHelper::SETTINGS_TAB })
        @variant = variant
      end

      attr_reader :variant

      def headers
        [
          [:setting, { caption: t("types.edit.overview.settings") }],
          [:configuration_mode, { caption: t("types.edit.overview.configuration_mode") }],
          [:dependents, { caption: t("types.edit.overview.dependents") }]
        ]
      end

      def mobile_title = t("types.edit.overview.tab")
    end
  end
end
