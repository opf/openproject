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
    # Service to extract comprehensive metadata from IFC files
    # Uses Python/IfcOpenShell for detailed IFC parsing
    class MetadataExtractorService
      def initialize(ifc_model)
        @ifc_model = ifc_model
        @ifc_file_path = ifc_model.ifc_attachment&.file&.path
      end

      def call
        return error_result('No IFC file attached') unless @ifc_file_path
        return error_result('IFC file not found') unless File.exist?(@ifc_file_path)

        Rails.logger.info "Extracting metadata for IFC model #{@ifc_model.id}"

        metadata = extract_metadata_via_python
        return error_result("Failed to extract metadata: #{metadata['error']}") if metadata['error']

        # Create or update metadata record
        ifc_metadata = @ifc_model.ifc_model_metadata || @ifc_model.build_ifc_model_metadata

        ifc_metadata.update!(
          ifc_version: detect_ifc_version,
          entity_count: count_entities,
          geometry_count: metadata['geometry_index']&.size || 0,
          spatial_structure: metadata['spatial_structure'] || {},
          property_sets: metadata['property_sets'] || {},
          quantities: metadata['quantities'] || {},
          classifications: metadata['classifications'] || {},
          materials: metadata['materials'] || {},
          element_index: metadata['element_index'] || {},
          geometry_index: metadata['geometry_index'] || {},
          file_checksum: calculate_checksum
        )

        ServiceResult.success(result: ifc_metadata)
      rescue StandardError => e
        Rails.logger.error "Metadata extraction failed: #{e.message}\n#{e.backtrace.join("\n")}"
        error_result("Extraction failed: #{e.message}")
      end

      def extract_element_properties(element_id)
        # Extract properties for a single element
        return {} unless @ifc_file_path && File.exist?(@ifc_file_path)

        metadata = @ifc_model.ifc_model_metadata
        return {} unless metadata

        metadata.find_element(element_id) || {}
      end

      private

      def extract_metadata_via_python
        script_path = Rails.root.join('lib', 'bim', 'python', 'extract_metadata.py')
        unless File.exist?(script_path)
          Rails.logger.error "Python metadata extraction script not found: #{script_path}"
          return { 'error' => 'Extraction script not available' }
        end

        cmd = "python3 #{script_path} #{Shellwords.escape(@ifc_file_path)}"
        output = `#{cmd} 2>&1`

        if $?.success?
          JSON.parse(output)
        else
          Rails.logger.error "Python script failed: #{output}"
          { 'error' => output }
        end
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse Python script output: #{e.message}"
        { 'error' => 'Invalid JSON output from extraction script' }
      end

      def detect_ifc_version
        header = File.read(@ifc_file_path, 1024)
        if header.match(/FILE_SCHEMA\s*\(\s*\(\s*'(IFC[^']+)'/i)
          Regexp.last_match(1).upcase
        end
      rescue StandardError
        nil
      end

      def count_entities
        count = 0
        File.foreach(@ifc_file_path) do |line|
          count += 1 if line.start_with?('#')
        end
        count
      rescue StandardError
        0
      end

      def calculate_checksum
        Digest::SHA256.file(@ifc_file_path).hexdigest
      rescue StandardError
        nil
      end

      def error_result(message)
        ServiceResult.failure(errors: [message])
      end
    end
  end
end
