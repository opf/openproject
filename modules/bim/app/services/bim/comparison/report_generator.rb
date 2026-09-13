# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Bim
  module Comparison
    ##
    # Service for generating comparison reports
    #
    # Generates:
    # - Summary report (change counts, statistics)
    # - Detailed change report (element-by-element)
    # - Type-based analysis
    # - Export to various formats
    #
    class ReportGenerator
      attr_reader :comparison

      def initialize(comparison)
        @comparison = comparison
      end

      ##
      # Generate complete report
      #
      # @return [Hash] Report data
      #
      def generate
        {
          summary: generate_summary,
          change_details: generate_change_details,
          type_analysis: generate_type_analysis,
          recommendations: generate_recommendations
        }
      end

      ##
      # Generate executive summary
      #
      def generate_summary
        {
          comparison_id: comparison.id,
          comparison_name: comparison.name || "#{comparison.model1.title} vs #{comparison.model2.title}",
          comparison_date: comparison.created_at,
          comparison_time: comparison.comparison_time,
          total_elements_model1: comparison.statistics['total_elements_model1'],
          total_elements_model2: comparison.statistics['total_elements_model2'],
          total_changes: comparison.total_changes,
          change_percentage: comparison.change_percentage,
          change_counts: {
            added: comparison.added_count,
            deleted: comparison.deleted_count,
            modified: comparison.modified_count,
            unchanged: comparison.unchanged_count
          }
        }
      end

      ##
      # Generate detailed change report
      #
      def generate_change_details
        {
          added_elements: format_added_elements,
          deleted_elements: format_deleted_elements,
          modified_elements: format_modified_elements
        }
      end

      ##
      # Generate type-based analysis
      #
      def generate_type_analysis
        comparison.changes_by_type
      end

      ##
      # Generate recommendations based on changes
      #
      def generate_recommendations
        recommendations = []

        if comparison.deleted_count > comparison.total_elements * 0.1
          recommendations << {
            level: :warning,
            message: "#{comparison.deleted_count} elements deleted (>10% of total) - verify intentional removal"
          }
        end

        if comparison.modified_count > comparison.total_elements * 0.2
          recommendations << {
            level: :info,
            message: "#{comparison.modified_count} elements modified (>20% of total) - major model update detected"
          }
        end

        recommendations
      end

      private

      def format_added_elements
        comparison.added_elements.map do |elem|
          {
            element_id: elem[:element_id],
            type: elem.dig(:element, 'properties', 'type'),
            name: elem.dig(:element, 'properties', 'name')
          }
        end
      end

      def format_deleted_elements
        comparison.deleted_elements.map do |elem|
          {
            element_id: elem[:element_id],
            type: elem.dig(:element, 'properties', 'type'),
            name: elem.dig(:element, 'properties', 'name')
          }
        end
      end

      def format_modified_elements
        comparison.modified_elements.map do |elem|
          {
            element_id: elem[:element_id],
            type: elem.dig(:element_after, 'properties', 'type'),
            name: elem.dig(:element_after, 'properties', 'name'),
            change_count: elem[:changes].size,
            changes: format_changes(elem[:changes])
          }
        end
      end

      def format_changes(changes)
        changes.map do |change|
          case change[:type]
          when 'geometry'
            "Geometry changed"
          when 'property'
            "#{change[:property]}: #{change[:old_value]} → #{change[:new_value]}"
          when 'element_type'
            "Type changed: #{change[:old_value]} → #{change[:new_value]}"
          else
            change[:description]
          end
        end
      end
    end
  end
end
