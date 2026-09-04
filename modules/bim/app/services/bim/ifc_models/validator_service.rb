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
    # Service to validate IFC files before conversion
    # Detects IFC version, validates schema, and analyzes complexity
    class ValidatorService
      LARGE_FILE_THRESHOLD = 1024 * 1024 * 1024 # 1GB
      COMPLEXITY_THRESHOLD = 100_000 # entities

      def initialize(ifc_file_path)
        @ifc_file_path = ifc_file_path
        @errors = []
        @warnings = []
      end

      def call
        return error_result('File not found') unless File.exist?(@ifc_file_path)

        file_size = File.size(@ifc_file_path)
        ifc_version = detect_ifc_version
        return error_result('Unable to detect IFC version') unless ifc_version

        schema_errors = validate_schema(ifc_version)
        complexity = analyze_complexity
        checksum = calculate_checksum

        # Check for warnings
        check_file_size_warnings(file_size)
        check_complexity_warnings(complexity[:entity_count])

        {
          valid: true,
          ifc_version:,
          schema_errors:,
          warnings: @warnings,
          file_size:,
          entity_count: complexity[:entity_count],
          geometry_count: complexity[:geometry_count],
          estimated_conversion_time: estimate_conversion_time(complexity[:entity_count]),
          file_checksum: checksum
        }
      end

      private

      def detect_ifc_version
        # Read first 1KB of file to detect IFC version from header
        header = File.read(@ifc_file_path, 1024)

        # Match FILE_SCHEMA(('IFC4')); or FILE_SCHEMA(('IFC2X3')); patterns
        if header.match(/FILE_SCHEMA\s*\(\s*\(\s*'(IFC[^']+)'/i)
          Regexp.last_match(1).upcase
        end
      rescue StandardError => e
        Rails.logger.error "Failed to detect IFC version: #{e.message}"
        nil
      end

      def validate_schema(ifc_version)
        # Basic schema validation
        # In a full implementation, this would call Python IfcOpenShell for detailed validation
        errors = []

        # Check if file is valid STEP format
        begin
          header = File.read(@ifc_file_path, 100)
          errors << 'Invalid STEP format: missing ISO-10303-21 header' unless header.start_with?('ISO-10303-21')
        rescue StandardError => e
          errors << "Unable to read file header: #{e.message}"
        end

        # TODO: Call Python script for detailed schema validation
        # errors += run_python_validation_script(ifc_version)

        errors
      end

      def analyze_complexity
        # Quick complexity analysis by counting entities in file
        entity_count = 0
        geometry_count = 0

        begin
          File.foreach(@ifc_file_path) do |line|
            # Count IFC entities (lines starting with #)
            if line.start_with?('#')
              entity_count += 1

              # Count geometry-related entities
              geometry_count += 1 if line.match?(/IFC(FACE|SHAPE|REPRESENTATION|SURFACE|CURVE)/i)
            end
          end
        rescue StandardError => e
          Rails.logger.warn "Failed to analyze complexity: #{e.message}"
        end

        { entity_count:, geometry_count: }
      end

      def calculate_checksum
        Digest::SHA256.file(@ifc_file_path).hexdigest
      rescue StandardError => e
        Rails.logger.error "Failed to calculate checksum: #{e.message}"
        nil
      end

      def estimate_conversion_time(entity_count)
        # Rough estimate: ~100 entities per second
        # Includes all stages: IFC→DAE→glTF→XKT→metadata
        base_time = (entity_count / 100.0).ceil

        # Add overhead for each stage (6 stages)
        stage_overhead = 30 # 30 seconds total overhead

        base_time + stage_overhead
      end

      def check_file_size_warnings(file_size)
        if file_size > LARGE_FILE_THRESHOLD
          @warnings << "Large file detected (#{file_size / (1024 * 1024)}MB). " \
                       'Conversion may take significant time and resources.'
        end
      end

      def check_complexity_warnings(entity_count)
        if entity_count > COMPLEXITY_THRESHOLD
          @warnings << "Complex model detected (#{entity_count} entities). " \
                       'Consider simplifying if conversion fails.'
        end
      end

      def error_result(message)
        {
          valid: false,
          schema_errors: [message],
          warnings: @warnings
        }
      end
    end
  end
end
