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
    module CustomFields
      class RowComponent < ::RowComponent
        def custom_field
          row
        end

        def name
          link_to(custom_field.name, helpers.edit_path(custom_field), lang: custom_field.name_locale)
        end

        def field_format
          helpers.label_for_custom_field_format(custom_field.field_format)
        end

        def is_required # rubocop:disable Naming/PredicatePrefix
          helpers.checked_image(custom_field.is_required?)
        end

        def used_in_projects
          reach = table.project_counts[custom_field.id].to_i

          if reach.zero?
            tag.span(t(:label_x_projects, count: reach), class: "icon-context icon-warning")
          else
            t(:label_x_projects, count: reach)
          end
        end

        def contained_in_type
          type_links = custom_field.type_variants.map do |variant|
            link_to(variant.composite_name, helpers.edit_variant_form_configuration_path(nil, variant))
          end

          if type_links.empty?
            tag.span(class: "icon-context icon-warning") do
              link_to(t(:label_custom_field_add_no_type), types_path)
            end
          else
            safe_join(type_links, ", ")
          end
        end

        def sort
          helpers.reorder_links("custom_field",
                                { action: "update", id: custom_field, back_url: helpers.index_path },
                                method: :put)
        end

        def button_links
          [render(Admin::CustomFields::DeleteButtonComponent.new(custom_field:))]
        end
      end
    end
  end
end
