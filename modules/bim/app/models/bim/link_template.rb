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

module Bim
  class LinkTemplate < ApplicationRecord
    self.table_name = 'bim_link_templates'

    # Associations
    belongs_to :project, optional: true
    belongs_to :author, class_name: 'User'
    has_many :element_links, foreign_key: :template_id, dependent: :nullify

    # Enums - same as ElementLink for consistency
    enum relationship_type: {
      affected_by: 0,
      responsible_for: 1,
      depends_on: 2,
      observes: 3,
      related_to: 4
    }

    # Validations
    validates :name, presence: true
    validates :name, uniqueness: { scope: :project_id }
    validates :relationship_type, presence: true
    validates :element_filters, presence: true
    validate :validate_element_filters_structure
    validate :validate_template_data_structure
    validate :validate_project_consistency

    # Scopes
    scope :public_templates, -> { where(public: true) }
    scope :private_templates, -> { where(public: false) }
    scope :auto_apply_templates, -> { where(auto_apply: true) }
    scope :for_project, ->(project_id) { where(project_id: [project_id, nil]).or(where(public: true)) }
    scope :by_relationship, ->(type) { where(relationship_type: type) }

    # Apply this template to create links for matching elements
    # @param work_package [WorkPackage] the work package to link elements to
    # @param ifc_model [Bim::IfcModels::IfcModel] the IFC model to search for elements
    # @param dry_run [Boolean] if true, return matching elements without creating links
    # @return [Array<Bim::ElementLink>] created links (or matching elements if dry_run)
    def apply_to(work_package:, ifc_model:, dry_run: false)
      matching_elements = find_matching_elements(ifc_model)

      return matching_elements if dry_run

      matching_elements.map do |element_id|
        ElementLink.create(
          work_package: work_package,
          ifc_model: ifc_model,
          element_id: element_id,
          relationship_type: relationship_type,
          template_id: id,
          element_properties: extract_element_properties(ifc_model, element_id)
        )
      end.compact
    end

    # Find elements in the IFC model that match the template's filters
    # @param ifc_model [Bim::IfcModels::IfcModel] the IFC model to search
    # @return [Array<String>] array of matching element IDs
    def find_matching_elements(ifc_model)
      return [] unless ifc_model&.xkt_attachment

      all_elements = ifc_model.metadata.dig('elements') || {}
      matching = []

      all_elements.each do |element_id, element_data|
        matching << element_id if element_matches_filters?(element_data)
      end

      matching
    end

    # Check if a single element matches all filters
    # @param element_data [Hash] element metadata from IFC model
    # @return [Boolean]
    def element_matches_filters?(element_data)
      return true if element_filters.blank?

      # Type filter (e.g., IfcWall, IfcDoor)
      if element_filters['types'].present?
        element_type = element_data.dig('properties', 'type')
        return false unless element_filters['types'].include?(element_type)
      end

      # Location filter (building, storey, space)
      if element_filters['locations'].present?
        location = {
          'building' => element_data.dig('spatial_structure', 'building'),
          'storey' => element_data.dig('spatial_structure', 'storey'),
          'space' => element_data.dig('spatial_structure', 'space')
        }
        return false unless location_matches?(location, element_filters['locations'])
      end

      # Classification filter (e.g., Uniclass, OmniClass)
      if element_filters['classifications'].present?
        classifications = element_data.dig('properties', 'classifications') || []
        return false unless classification_matches?(classifications, element_filters['classifications'])
      end

      # Property filter (custom property values)
      if element_filters['properties'].present?
        return false unless properties_match?(element_data, element_filters['properties'])
      end

      # Tag filter
      if element_filters['tags'].present?
        tags = element_data.dig('properties', 'tags') || []
        return false unless (element_filters['tags'] & tags).any?
      end

      true
    end

    # Get template statistics
    # @return [Hash] statistics about template usage
    def statistics
      {
        total_links: element_links.count,
        active_links: element_links.active.count,
        completed_links: element_links.completed.count,
        archived_links: element_links.archived.count,
        work_packages: element_links.select(:work_package_id).distinct.count,
        ifc_models: element_links.select(:ifc_model_id).distinct.count
      }
    end

    # Clone template with optional modifications
    # @param new_name [String] name for the cloned template
    # @param modifications [Hash] attributes to modify in the clone
    # @return [Bim::LinkTemplate] the cloned template
    def clone_template(new_name:, modifications: {})
      cloned = self.class.new(
        name: new_name,
        description: description,
        relationship_type: relationship_type,
        work_package_type: work_package_type,
        element_filters: element_filters.deep_dup,
        template_data: template_data.deep_dup,
        auto_apply: auto_apply,
        public: false, # Clones are private by default
        project_id: project_id,
        author: author
      )

      modifications.each do |key, value|
        cloned.send("#{key}=", value) if cloned.respond_to?("#{key}=")
      end

      cloned
    end

    private

    def validate_element_filters_structure
      return if element_filters.blank?

      valid_keys = %w[types locations classifications properties tags]
      invalid_keys = element_filters.keys - valid_keys

      errors.add(:element_filters, "contains invalid keys: #{invalid_keys.join(', ')}") if invalid_keys.any?

      # Validate types is an array
      if element_filters['types'].present? && !element_filters['types'].is_a?(Array)
        errors.add(:element_filters, "types must be an array")
      end

      # Validate locations is a hash
      if element_filters['locations'].present? && !element_filters['locations'].is_a?(Hash)
        errors.add(:element_filters, "locations must be a hash")
      end

      # Validate classifications is an array
      if element_filters['classifications'].present? && !element_filters['classifications'].is_a?(Array)
        errors.add(:element_filters, "classifications must be an array")
      end

      # Validate properties is a hash
      if element_filters['properties'].present? && !element_filters['properties'].is_a?(Hash)
        errors.add(:element_filters, "properties must be a hash")
      end

      # Validate tags is an array
      if element_filters['tags'].present? && !element_filters['tags'].is_a?(Array)
        errors.add(:element_filters, "tags must be an array")
      end
    end

    def validate_template_data_structure
      return if template_data.blank?

      # Template data can contain any additional configuration
      # Just ensure it's a hash
      unless template_data.is_a?(Hash)
        errors.add(:template_data, "must be a hash")
      end
    end

    def validate_project_consistency
      # Public templates cannot be project-specific
      if public? && project_id.present?
        errors.add(:base, "Public templates cannot be project-specific")
      end

      # Private templates must have either project or author
      if !public? && project_id.blank? && author_id.blank?
        errors.add(:base, "Private templates must have a project or author")
      end
    end

    def location_matches?(element_location, filter_locations)
      filter_locations.all? do |key, values|
        next true if values.blank?
        values.include?(element_location[key])
      end
    end

    def classification_matches?(element_classifications, filter_classifications)
      filter_classifications.any? do |filter|
        element_classifications.any? do |classification|
          classification['system'] == filter['system'] &&
            classification['code'] == filter['code']
        end
      end
    end

    def properties_match?(element_data, filter_properties)
      filter_properties.all? do |key, value|
        element_value = element_data.dig('properties', key)
        case value
        when Hash
          # Support operators like { "gt": 100 }, { "eq": "value" }
          value.all? { |op, val| compare_property(element_value, op, val) }
        else
          element_value == value
        end
      end
    end

    def compare_property(element_value, operator, filter_value)
      return false if element_value.nil?

      case operator.to_s
      when 'eq' then element_value == filter_value
      when 'ne' then element_value != filter_value
      when 'gt' then element_value.to_f > filter_value.to_f
      when 'gte' then element_value.to_f >= filter_value.to_f
      when 'lt' then element_value.to_f < filter_value.to_f
      when 'lte' then element_value.to_f <= filter_value.to_f
      when 'contains' then element_value.to_s.include?(filter_value.to_s)
      when 'matches' then element_value.to_s.match?(Regexp.new(filter_value.to_s))
      else false
      end
    end

    def extract_element_properties(ifc_model, element_id)
      element_data = ifc_model.metadata.dig('elements', element_id)
      return {} unless element_data

      {
        'type' => element_data.dig('properties', 'type'),
        'name' => element_data.dig('properties', 'name'),
        'spatial_structure' => element_data['spatial_structure'],
        'geometry' => element_data['geometry'],
        'classifications' => element_data.dig('properties', 'classifications'),
        'captured_at' => Time.current.iso8601
      }
    end
  end
end
