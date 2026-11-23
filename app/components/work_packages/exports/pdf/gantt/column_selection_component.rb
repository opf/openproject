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

module WorkPackages
  module Exports
    module PDF
      module Gantt
        class ColumnSelectionComponent < WorkPackages::Exports::ColumnSelectionComponent
          def initialize(export_settings)
            super(
              export_settings,
              "columns-select-export-pdf-gantt",
              I18n.t("export.dialog.columns.input_caption_gantt",
                     count: ::Exports::PDF::Components::Gantt::TextColumns::MAX_COLUMNS),
              I18n.t("export.dialog.columns.input_label_gantt"),
              max_columns: ::Exports::PDF::Components::Gantt::TextColumns::MAX_COLUMNS
            )
          end

          def default_columns
            text_columns.defaults.map { |column| { id: column.name.to_s, name: column.caption } }
          end

          def excluded_column?(column)
            !text_columns.allowed?(column)
          end

          private

          def text_columns
            @text_columns ||= ::Exports::PDF::Components::Gantt::TextColumns.new(query)
          end
        end
      end
    end
  end
end
