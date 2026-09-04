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
  class BulkLinkOperationsService
    attr_reader :current_user

    def initialize(current_user:)
      @current_user = current_user
    end

    # Create multiple links at once
    # @param work_package [WorkPackage] the work package to link elements to
    # @param ifc_model [Bim::IfcModels::IfcModel] the IFC model containing elements
    # @param element_ids [Array<String>] array of element IDs to link
    # @param relationship_type [Symbol] type of relationship
    # @param template [Bim::LinkTemplate, nil] optional template used for creation
    # @return [ServiceResult] with created links or errors
    def create_bulk_links(work_package:, ifc_model:, element_ids:, relationship_type:, template: nil)
      return error_result('No element IDs provided') if element_ids.blank?
      return error_result('Invalid relationship type') unless valid_relationship_type?(relationship_type)

      created_links = []
      failed_links = []

      element_ids.each do |element_id|
        link = ElementLink.new(
          work_package: work_package,
          ifc_model: ifc_model,
          element_id: element_id,
          relationship_type: relationship_type,
          template: template,
          user: current_user,
          element_properties: extract_element_properties(ifc_model, element_id)
        )

        if link.save
          created_links << link
        else
          failed_links << { element_id: element_id, errors: link.errors.full_messages }
        end
      end

      result_data = {
        created: created_links,
        failed: failed_links,
        success_count: created_links.size,
        failure_count: failed_links.size
      }

      if failed_links.empty?
        success_result(result_data)
      else
        partial_success_result(result_data)
      end
    end

    # Apply a template to create links for all matching elements
    # @param work_package [WorkPackage] the work package to link elements to
    # @param ifc_model [Bim::IfcModels::IfcModel] the IFC model to search
    # @param template [Bim::LinkTemplate] template defining filters and relationship
    # @param dry_run [Boolean] if true, return matching elements without creating links
    # @return [ServiceResult] with created links or matching element IDs
    def apply_template(work_package:, ifc_model:, template:, dry_run: false)
      matching_elements = template.find_matching_elements(ifc_model)

      return success_result({ matching_elements: matching_elements, count: matching_elements.size }) if dry_run

      create_bulk_links(
        work_package: work_package,
        ifc_model: ifc_model,
        element_ids: matching_elements,
        relationship_type: template.relationship_type,
        template: template
      )
    end

    # Update multiple links at once
    # @param link_ids [Array<Integer>] IDs of links to update
    # @param attributes [Hash] attributes to update
    # @return [ServiceResult] with updated links or errors
    def update_bulk_links(link_ids:, attributes:)
      return error_result('No link IDs provided') if link_ids.blank?
      return error_result('No attributes to update') if attributes.blank?

      links = ElementLink.where(id: link_ids)
      return error_result('No links found') if links.empty?

      updated_links = []
      failed_links = []

      links.each do |link|
        if link.update(attributes)
          updated_links << link
        else
          failed_links << { link_id: link.id, errors: link.errors.full_messages }
        end
      end

      result_data = {
        updated: updated_links,
        failed: failed_links,
        success_count: updated_links.size,
        failure_count: failed_links.size
      }

      if failed_links.empty?
        success_result(result_data)
      else
        partial_success_result(result_data)
      end
    end

    # Delete multiple links at once
    # @param link_ids [Array<Integer>] IDs of links to delete
    # @param soft_delete [Boolean] if true, archive instead of delete
    # @return [ServiceResult] with deleted link count
    def delete_bulk_links(link_ids:, soft_delete: true)
      return error_result('No link IDs provided') if link_ids.blank?

      links = ElementLink.where(id: link_ids)
      return error_result('No links found') if links.empty?

      if soft_delete
        archived = links.update_all(status: :archived)
        success_result({ archived_count: archived, link_ids: link_ids })
      else
        deleted = links.destroy_all
        success_result({ deleted_count: deleted.size, link_ids: link_ids })
      end
    end

    # Create work packages from element selections using templates
    # @param ifc_model [Bim::IfcModels::IfcModel] the IFC model
    # @param element_ids [Array<String>] elements to create work packages for
    # @param work_package_template [Hash] template for work package creation
    # @param relationship_type [Symbol] how elements relate to work packages
    # @param grouping_strategy [Symbol] how to group elements (:individual, :by_type, :by_location, :all_in_one)
    # @return [ServiceResult] with created work packages and links
    def create_work_packages_from_elements(ifc_model:, element_ids:, work_package_template:, relationship_type:, grouping_strategy: :individual)
      return error_result('No element IDs provided') if element_ids.blank?
      return error_result('Invalid work package template') if work_package_template.blank?

      grouped_elements = group_elements(ifc_model, element_ids, grouping_strategy)
      created_work_packages = []
      created_links = []
      failures = []

      grouped_elements.each do |group_key, element_group|
        wp_attributes = prepare_work_package_attributes(
          work_package_template,
          ifc_model,
          element_group,
          group_key
        )

        work_package = WorkPackage.new(wp_attributes)

        if work_package.save
          created_work_packages << work_package

          # Create links for all elements in this group
          link_result = create_bulk_links(
            work_package: work_package,
            ifc_model: ifc_model,
            element_ids: element_group,
            relationship_type: relationship_type
          )

          created_links.concat(link_result[:created]) if link_result.success?
        else
          failures << { group_key: group_key, errors: work_package.errors.full_messages }
        end
      end

      result_data = {
        work_packages: created_work_packages,
        links: created_links,
        failures: failures,
        work_package_count: created_work_packages.size,
        link_count: created_links.size
      }

      if failures.empty?
        success_result(result_data)
      else
        partial_success_result(result_data)
      end
    end

    # Refresh element properties for multiple links
    # @param link_ids [Array<Integer>] IDs of links to refresh
    # @return [ServiceResult] with refresh results
    def refresh_element_properties(link_ids:)
      return error_result('No link IDs provided') if link_ids.blank?

      links = ElementLink.where(id: link_ids).includes(:ifc_model)
      return error_result('No links found') if links.empty?

      refreshed = []
      failed = []
      changed = []

      links.each do |link|
        had_changes = link.geometry_changed? || link.properties_changed?

        if link.refresh_element_properties!
          refreshed << link
          changed << link if had_changes
        else
          failed << { link_id: link.id, reason: 'Element not found or metadata unavailable' }
        end
      end

      success_result({
        refreshed: refreshed,
        changed: changed,
        failed: failed,
        refreshed_count: refreshed.size,
        changed_count: changed.size,
        failed_count: failed.size
      })
    end

    # Find elements matching criteria across one or more IFC models
    # @param ifc_models [Array<Bim::IfcModels::IfcModel>] models to search
    # @param filters [Hash] element filters (same structure as LinkTemplate filters)
    # @return [ServiceResult] with matching elements grouped by model
    def find_matching_elements(ifc_models:, filters:)
      return error_result('No IFC models provided') if ifc_models.blank?
      return error_result('No filters provided') if filters.blank?

      results = {}

      ifc_models.each do |ifc_model|
        # Create a temporary template to reuse filtering logic
        temp_template = LinkTemplate.new(
          name: 'temp',
          relationship_type: :related_to,
          element_filters: filters,
          author: current_user
        )

        matching = temp_template.find_matching_elements(ifc_model)
        results[ifc_model.id] = {
          model: ifc_model,
          element_ids: matching,
          count: matching.size
        }
      end

      total_count = results.values.sum { |r| r[:count] }

      success_result({
        results: results,
        total_count: total_count,
        model_count: results.size
      })
    end

    # Bulk status change for links
    # @param link_ids [Array<Integer>] IDs of links to update
    # @param new_status [Symbol] new status (:active, :completed, :archived)
    # @return [ServiceResult]
    def bulk_status_change(link_ids:, new_status:)
      return error_result('No link IDs provided') if link_ids.blank?
      return error_result('Invalid status') unless valid_status?(new_status)

      updated_count = ElementLink.where(id: link_ids).update_all(status: new_status)

      success_result({
        updated_count: updated_count,
        new_status: new_status,
        link_ids: link_ids
      })
    end

    private

    def valid_relationship_type?(type)
      ElementLink.relationship_types.key?(type.to_s)
    end

    def valid_status?(status)
      ElementLink.statuses.key?(status.to_s)
    end

    def extract_element_properties(ifc_model, element_id)
      element_data = ifc_model.metadata&.dig('elements', element_id)
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

    def group_elements(ifc_model, element_ids, strategy)
      elements_metadata = element_ids.map do |id|
        { id: id, metadata: ifc_model.metadata&.dig('elements', id) }
      end.compact

      case strategy
      when :individual
        element_ids.index_with { |id| [id] }
      when :by_type
        elements_metadata.group_by { |e| e[:metadata]&.dig('properties', 'type') || 'Unknown' }
                         .transform_values { |elements| elements.map { |e| e[:id] } }
      when :by_location
        elements_metadata.group_by { |e| e[:metadata]&.dig('spatial_structure', 'storey') || 'Unassigned' }
                         .transform_values { |elements| elements.map { |e| e[:id] } }
      when :all_in_one
        { 'all' => element_ids }
      else
        element_ids.index_with { |id| [id] }
      end
    end

    def prepare_work_package_attributes(template, ifc_model, element_ids, group_key)
      # Get first element for reference
      first_element = ifc_model.metadata&.dig('elements', element_ids.first)

      attributes = template.dup
      attributes[:project_id] ||= ifc_model.project_id

      # Customize subject based on grouping
      if template[:subject].blank?
        attributes[:subject] = case group_key
                               when 'all'
                                 "Work on #{element_ids.size} elements in #{ifc_model.title}"
                               else
                                 "Work on #{group_key} (#{element_ids.size} elements)"
                               end
      else
        # Replace placeholders in subject
        attributes[:subject] = template[:subject]
                               .gsub('{count}', element_ids.size.to_s)
                               .gsub('{group}', group_key.to_s)
                               .gsub('{model}', ifc_model.title)
      end

      # Add element information to description
      if first_element
        element_info = "\n\nLinked BIM Elements (#{element_ids.size}):\n"
        element_info += "- Location: #{first_element.dig('spatial_structure', 'storey')}\n" if first_element.dig('spatial_structure', 'storey')
        element_info += "- Type: #{first_element.dig('properties', 'type')}\n" if first_element.dig('properties', 'type')

        attributes[:description] = "#{attributes[:description]}#{element_info}"
      end

      attributes
    end

    def success_result(data)
      ServiceResult.success(result: data)
    end

    def error_result(message)
      ServiceResult.failure(message: message)
    end

    def partial_success_result(data)
      ServiceResult.new(
        success: true,
        result: data,
        message: "Operation completed with #{data[:failure_count]} failures"
      )
    end
  end
end
