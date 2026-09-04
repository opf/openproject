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
  class ElementLink < ApplicationRecord
    self.table_name = 'bim_element_links'

    # Relationship types define why an element is linked to a work package
    enum relationship_type: {
      affected_by: 0,       # Element is affected by this work package/issue
      responsible_for: 1,   # Work package tracks work on this element
      depends_on: 2,        # Work package depends on this element's state
      observes: 3,          # Monitoring element status
      related_to: 4         # General relationship
    }

    # Link statuses track the lifecycle of the relationship
    enum status: {
      active: 0,       # Link is currently relevant
      completed: 1,    # Work on this link is complete
      archived: 2      # Link is archived but preserved for history
    }

    belongs_to :work_package, class_name: 'WorkPackage'
    belongs_to :ifc_model, class_name: 'Bim::IfcModels::IfcModel'
    belongs_to :user, optional: true

    validates :element_id, presence: true, length: { maximum: 50 }
    validates :element_id, uniqueness: { scope: :work_package_id }
    validates :relationship_type, presence: true
    validates :status, presence: true

    validate :validate_element_exists_in_model

    scope :active, -> { where(status: :active) }
    scope :completed, -> { where(status: :completed) }
    scope :archived, -> { where(status: :archived) }
    scope :by_element_type, ->(type) { where(element_type: type) }
    scope :by_relationship, ->(rel) { where(relationship_type: rel) }
    scope :for_work_package, ->(wp_id) { where(work_package_id: wp_id) }
    scope :for_ifc_model, ->(model_id) { where(ifc_model_id: model_id) }
    scope :for_element, ->(element_id) { where(element_id: element_id) }

    # Get current element metadata from the IFC model
    def element_metadata
      @element_metadata ||= ifc_model.ifc_model_metadata&.find_element(element_id)
    end

    # Check if element geometry has changed since link was created
    def geometry_changed?
      current = element_metadata
      return false unless current && element_properties

      # Compare geometry hash if available
      current_hash = current.dig('geometry', 'hash')
      stored_hash = element_properties.dig('geometry', 'hash')

      return false unless current_hash && stored_hash

      current_hash != stored_hash
    end

    # Check if element properties have changed since link was created
    def properties_changed?
      current = element_metadata
      return false unless current && element_properties

      # Compare key properties
      current_props = current.dig('properties') || {}
      stored_props = element_properties.dig('properties') || {}

      current_props != stored_props
    end

    # Get element display name (tries element_name, then metadata name, then element_id)
    def display_name
      element_name.presence || element_metadata&.dig('name') || element_id
    end

    # Get element type display (tries element_type, then metadata type)
    def display_type
      element_type.presence || element_metadata&.dig('type') || 'Unknown'
    end

    # Get element's current location in building hierarchy
    def element_location
      return nil unless element_metadata

      {
        building: element_metadata.dig('spatial_structure', 'building'),
        storey: element_metadata.dig('spatial_structure', 'storey'),
        space: element_metadata.dig('spatial_structure', 'space')
      }
    end

    # Get element's classification (e.g., Uniclass, OmniClass)
    def element_classification
      element_metadata&.dig('classification')
    end

    # Get element's property sets
    def element_property_sets
      element_metadata&.dig('property_sets') || {}
    end

    # Get element's quantities (area, volume, etc.)
    def element_quantities
      element_metadata&.dig('quantities') || {}
    end

    # Update element properties snapshot from current metadata
    def refresh_element_properties!
      current = element_metadata
      return false unless current

      update(
        element_properties: current,
        element_name: current['name'],
        element_type: current['type']
      )
    end

    # Get changes summary if properties or geometry changed
    def changes_summary
      changes = []

      changes << 'Geometry modified' if geometry_changed?
      changes << 'Properties modified' if properties_changed?

      changes.empty? ? nil : changes
    end

    # Check if element still exists in model
    def element_exists?
      element_metadata.present?
    end

    # Mark link as completed
    def complete!
      update(status: :completed)
    end

    # Mark link as archived
    def archive!
      update(status: :archived)
    end

    # Reactivate archived link
    def reactivate!
      update(status: :active)
    end

    private

    def validate_element_exists_in_model
      return unless ifc_model && element_id

      # Only validate if IFC model has metadata extracted
      return unless ifc_model.ifc_model_metadata

      unless ifc_model.ifc_model_metadata.find_element(element_id)
        errors.add(:element_id, "does not exist in IFC model '#{ifc_model.title}'")
      end
    end
  end
end
