# frozen_string_literal: true

# -- copyright
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
# ++

module Bim
  module IfcModels
    class IfcModelMetadata < ApplicationRecord
      self.table_name = 'ifc_model_metadata'

      belongs_to :ifc_model, class_name: 'Bim::IfcModels::IfcModel'

      validates :ifc_model_id, uniqueness: true

      # Find element properties by IFC GUID
      def find_element(element_id)
        element_index[element_id]
      end

      # Find elements by type (e.g., 'IfcWall', 'IfcDoor')
      def find_elements_by_type(element_type)
        element_index.select { |_id, props| props['type'] == element_type }
      end

      # Get spatial hierarchy as nested hash
      def spatial_hierarchy
        spatial_structure.presence || build_default_hierarchy
      end

      # Get all property sets
      def all_property_sets
        property_sets.presence || {}
      end

      # Get quantity takeoffs
      def quantity_takeoffs
        quantities.presence || {}
      end

      # Calculate total quantities
      def total_area
        quantities.dig('totals', 'area') || 0
      end

      def total_volume
        quantities.dig('totals', 'volume') || 0
      end

      # Check if metadata is complete
      def complete?
        ifc_version.present? && entity_count.present? && element_index.present?
      end

      private

      def build_default_hierarchy
        {
          'IfcProject' => {
            'name' => ifc_model.title,
            'children' => []
          }
        }
      end
    end
  end
end
