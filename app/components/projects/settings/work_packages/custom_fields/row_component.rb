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

module Projects
  module Settings
    module WorkPackages
      module CustomFields
        class RowComponent < OpPrimer::BorderBoxRowComponent
          delegate :variants_for, :variant_path, :linked?, to: :table

          def row_css_id = "project-custom-field-#{model.id}"

          def row_data = { test_selector: row_css_id }

          def custom_field
            render(Primer::Beta::Text.new(font_weight: :bold)) { model.name }
          end

          def variants
            safe_join(variants_for(model).map { |variant| variant_name(variant) }, ", ")
          end

          private

          def variant_name(variant)
            if linked?(variant)
              render(Primer::Beta::Link.new(href: variant_path(variant))) { variant.composite_name }
            else
              render(Primer::Beta::Text.new(color: :muted)) { variant.composite_name }
            end
          end
        end
      end
    end
  end
end
