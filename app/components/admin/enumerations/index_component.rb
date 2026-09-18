# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

module Admin
  module Enumerations
    class IndexComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(enumerations:)
        super()
        @enumerations = enumerations
      end

      private

      attr_reader :enumerations

      def wrapper_data_attributes
        {
          controller: "sortable-lists",
          sortable_lists_move_url_template_value: move_url_template,
          sortable_lists_sortable_lists__list_outlet: "##{wrapper_key} [data-controller~='sortable-lists--list']",
          sortable_lists_sortable_lists__item_outlet: "##{wrapper_key} [data-controller~='sortable-lists--item']"
        }
      end

      # Built from the route helper with a sentinel so relative-URL-root
      # installations keep working; {id} is expanded client-side.
      def move_url_template
        id_placeholder = "__id__"
        helpers.url_for(action: :move, id: id_placeholder).sub(id_placeholder, "{id}")
      end

      def list_data
        {
          controller: "sortable-lists--list",
          sortable_lists__list_type_value: sortable_list_type,
          sortable_lists__list_accepted_type_value: sortable_list_type,
          sortable_lists__list_name_value: enumeration_title
        }
      end

      def item_data(enumeration)
        {
          controller: "sortable-lists--item",
          sortable_lists__item_id_value: enumeration.id,
          sortable_lists__item_type_value: sortable_list_type,
          sortable_lists__item_label_value: enumeration.name
        }
      end

      def sortable_list_type
        enumeration_class.model_name.param_key
      end

      def enumeration_class
        enumerations.klass
      end

      def enumeration_title
        enumeration_class.model_name.human(count: :other)
      end

      def item_component_class
        ItemComponent
      end
    end
  end
end
