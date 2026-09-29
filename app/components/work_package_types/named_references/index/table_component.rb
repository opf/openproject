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
  module NamedReferences
    module Index
      class TableComponent < OpPrimer::BorderBoxTableComponent
        columns :name, :types_and_variants, :projects
        main_column :name
        mobile_labels :types_and_variants, :projects

        def initialize(records:, variants:, model_class:, filtered: false)
          super(rows: records)

          @variants = variants
          @model_class = model_class
          @filtered = filtered
        end

        attr_reader :model_class

        def icon = { ::Workflow => :workflow }.fetch(model_class)

        def mobile_title = model_class.model_name.human(count: 2)

        def pagination_params = { allowed_params: %w[filters] }

        def headers
          columns.map { |column| [column, { caption: model_class.reference_t("index.columns.#{column}") }] }
        end

        def has_actions? = true

        def variants_for(record) = @variants.fetch(record.id, [])

        def blank_title
          model_class.reference_t(@filtered ? "index.blank_slate.filtered_title" : "index.blank_slate.title")
        end

        def blank_description
          model_class.reference_t(@filtered ? "index.blank_slate.filtered_description" : "index.blank_slate.description")
        end

        def blank_icon = icon
      end
    end
  end
end
