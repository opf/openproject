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
  module CustomFields
    module TypesAndVariants
      class RowComponent < OpPrimer::BorderBoxRowComponent
        include WorkPackageTypes::VariantRoutes

        alias_method :variant, :model

        def row_data = { test_selector: "custom-field-type-variant-row-#{variant.id}" }

        def type_or_variant
          render(Primer::Beta::Link.new(href: edit_variant_form_configuration_path(variant.project, variant),
                                        font_weight: :bold)) do
            variant.composite_name
          end
        end

        def form
          form_configuration = variant.form_configuration
          return render(Primer::Beta::Text.new(color: :muted)) { "-" } if form_configuration.nil?

          render(Primer::Beta::Link.new(href: helpers.edit_polymorphic_path(form_configuration))) do
            form_configuration.name
          end
        end
      end
    end
  end
end
