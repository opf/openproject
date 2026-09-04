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

##
# IFC Upload Enhancement Demo Data Seeder
#
# Creates demonstration data for IFC upload enhancements including:
# - IFC models with comprehensive metadata
# - Conversion tracking examples
# - Validation results
#
# Usage:
#   rails runner modules/bim/db/seeds/ifc_upload_demo_data.rb
#

module Bim
  module Seeds
    class IfcUploadDemoData
      def self.seed!
        new.seed!
      end

      def seed!
        puts "🌱 Seeding IFC Upload Enhancement demo data..."

        @project = find_or_create_demo_project
        puts "✓ Using project: #{@project.name}"

        @user = User.admin.first || User.first
        puts "✓ Using user: #{@user.name}"

        @ifc_models = create_ifc_models
        puts "✓ Created #{@ifc_models.size} IFC models with metadata"

        print_summary

        puts "\n✅ IFC Upload Enhancement demo data seeded successfully!"
      end

      private

      def find_or_create_demo_project
        Project.find_or_create_by!(identifier: 'ifc-upload-demo') do |p|
          p.name = 'IFC Upload Enhancement Demo'
          p.description = 'Demonstration project for IFC upload enhancements'
          p.enabled_module_names = %w[bim work_package_tracking]
        end
      end

      def create_ifc_models
        models = []

        # Model 1: Simple IFC4 model (completed conversion)
        models << create_model_with_metadata(
          title: 'Office Building - IFC4',
          ifc_version: 'IFC4',
          entity_count: 45_000,
          geometry_count: 22_000,
          conversion_status: :completed,
          conversion_progress: 100,
          complexity: 0.5,
          has_warnings: false
        )

        # Model 2: Complex IFC2X3 model (with warnings)
        models << create_model_with_metadata(
          title: 'Hospital Complex - IFC2X3',
          ifc_version: 'IFC2X3',
          entity_count: 150_000,
          geometry_count: 75_000,
          conversion_status: :completed,
          conversion_progress: 100,
          complexity: 0.85,
          has_warnings: true
        )

        # Model 3: Model currently converting
        models << create_model_with_metadata(
          title: 'Residential Tower - IFC4',
          ifc_version: 'IFC4',
          entity_count: 80_000,
          geometry_count: 40_000,
          conversion_status: :processing,
          conversion_progress: 65,
          complexity: 0.7,
          has_warnings: false,
          current_stage: 'gltf_to_xkt'
        )

        # Model 4: Model with conversion error
        models << create_model_with_metadata(
          title: 'Shopping Mall - IFC4 (Error)',
          ifc_version: 'IFC4',
          entity_count: 120_000,
          geometry_count: 60_000,
          conversion_status: :error,
          conversion_progress: 35,
          complexity: 0.75,
          has_warnings: true,
          error_message: 'Failed to convert geometry: Invalid BREP representation in element #12345'
        )

        # Model 5: Duplicate model (same checksum as Model 1)
        models << create_model_with_metadata(
          title: 'Office Building - Copy',
          ifc_version: 'IFC4',
          entity_count: 45_000,
          geometry_count: 22_000,
          conversion_status: :completed,
          conversion_progress: 100,
          complexity: 0.5,
          has_warnings: false,
          duplicate_of: models.first&.ifc_model_metadata
        )

        models.compact
      end

      def create_model_with_metadata(options)
        # Create IFC model
        ifc_model = Bim::IfcModels::IfcModel.create!(
          project: @project,
          uploader: @user,
          title: options[:title],
          conversion_status: options[:conversion_status] || :completed,
          conversion_progress: options[:conversion_progress] || 100,
          conversion_stage: options[:current_stage],
          conversion_error_message: options[:error_message],
          conversion_started_at: 1.hour.ago,
          conversion_completed_at: options[:conversion_status] == :completed ? 30.minutes.ago : nil
        )

        # Add conversion logs
        add_conversion_logs(ifc_model, options[:conversion_status], options[:current_stage])

        # Create metadata
        metadata = create_metadata(ifc_model, options)

        ifc_model
      rescue StandardError => e
        puts "  ⚠️  Error creating model '#{options[:title]}': #{e.message}"
        nil
      end

      def create_metadata(ifc_model, options)
        checksum = if options[:duplicate_of]
                     options[:duplicate_of].file_checksum
                   else
                     Digest::SHA256.hexdigest("#{ifc_model.title}-#{Time.current}")
                   end

        warnings = if options[:has_warnings]
                     generate_warnings(options[:complexity], options[:entity_count])
                   else
                     []
                   end

        Bim::IfcModels::IfcModelMetadata.create!(
          ifc_model: ifc_model,
          ifc_version: options[:ifc_version],
          file_schema: schema_for_version(options[:ifc_version]),
          file_checksum: checksum,
          entity_count: options[:entity_count],
          geometry_count: options[:geometry_count],
          spatial_structure: generate_spatial_structure(options[:title]),
          property_sets: generate_property_sets,
          quantities: generate_quantities,
          classifications: generate_classifications,
          materials: generate_materials,
          types: generate_types,
          validation_result: {
            warnings: warnings,
            errors: [],
            complexity_score: options[:complexity]
          },
          estimated_conversion_time: (options[:entity_count] / 100.0).ceil + 30,
          actual_conversion_time: options[:conversion_status] == :completed ? (options[:entity_count] / 120.0).ceil + 25 : nil
        )
      end

      def add_conversion_logs(ifc_model, status, current_stage)
        logs = []

        # Validation stage
        logs << log_entry('validation', 'info', 'Starting Validation', completed: true)
        logs << log_entry('validation', 'info', 'Validation completed successfully', completed: true)

        # IFC to DAE
        logs << log_entry('ifc_to_dae', 'info', 'Converting IFC to COLLADA (DAE)', completed: status != :processing || current_stage != 'ifc_to_dae')

        if status == :processing && current_stage == 'ifc_to_dae'
          return ifc_model.update!(conversion_logs: logs)
        end

        logs << log_entry('ifc_to_dae', 'info', 'DAE conversion completed', completed: true)

        # DAE to glTF
        logs << log_entry('dae_to_gltf', 'info', 'Converting DAE to glTF', completed: status != :processing || current_stage != 'dae_to_gltf')

        if status == :processing && current_stage == 'dae_to_gltf'
          return ifc_model.update!(conversion_logs: logs)
        end

        logs << log_entry('dae_to_gltf', 'info', 'glTF conversion completed', completed: true)

        # glTF to XKT
        logs << log_entry('gltf_to_xkt', 'info', 'Converting glTF to XKT', completed: status != :processing || current_stage != 'gltf_to_xkt')

        if status == :error
          logs << log_entry('gltf_to_xkt', 'error', ifc_model.conversion_error_message || 'Conversion failed', completed: false)
          return ifc_model.update!(conversion_logs: logs)
        end

        if status == :processing && current_stage == 'gltf_to_xkt'
          return ifc_model.update!(conversion_logs: logs)
        end

        logs << log_entry('gltf_to_xkt', 'info', 'XKT conversion completed', completed: true)

        # Enhanced metadata
        logs << log_entry('enhanced_metadata', 'info', 'Extracting enhanced metadata', completed: true)
        logs << log_entry('enhanced_metadata', 'info', 'Metadata extracted successfully', completed: true)

        ifc_model.update!(conversion_logs: logs)
      end

      def log_entry(stage, level, message, completed:)
        {
          stage: stage,
          level: level,
          message: message,
          timestamp: (completed ? 1.hour.ago : Time.current).iso8601,
          details: {}
        }
      end

      def generate_warnings(complexity, entity_count)
        warnings = []

        if complexity > 0.7
          warnings << "Complex model detected (#{entity_count} entities). Consider simplifying if conversion fails."
        end

        if entity_count > 100_000
          warnings << 'Large entity count may result in longer conversion times.'
        end

        warnings
      end

      def schema_for_version(version)
        case version
        when 'IFC4'
          'IFC4_ADD2'
        when 'IFC2X3'
          'IFC2X3_TC1'
        else
          'UNKNOWN'
        end
      end

      def generate_spatial_structure(title)
        building_name = title.split(' - ').first

        {
          'type' => 'IfcProject',
          'name' => "#{building_name} Project",
          'guid' => SecureRandom.uuid,
          'children' => [
            {
              'type' => 'IfcSite',
              'name' => 'Site',
              'children' => [
                {
                  'type' => 'IfcBuilding',
                  'name' => building_name,
                  'children' => building_storeys
                }
              ]
            }
          ]
        }
      end

      def building_storeys
        (1..5).map do |level|
          {
            'type' => 'IfcBuildingStorey',
            'name' => "Level #{level}",
            'guid' => SecureRandom.uuid,
            'elevation' => (level - 1) * 3.5,
            'children' => [
              { 'type' => 'IfcSpace', 'name' => "Office #{level}01", 'area' => 25.0 },
              { 'type' => 'IfcSpace', 'name' => "Office #{level}02", 'area' => 30.0 }
            ]
          }
        end
      end

      def generate_property_sets
        {
          'Pset_BuildingCommon' => {
            'properties' => {
              'BuildingID' => { 'value' => 'B-001' },
              'YearOfConstruction' => { 'value' => 2023 },
              'NumberOfStoreys' => { 'value' => 5 }
            }
          },
          'Pset_WallCommon' => {
            'properties' => {
              'IsExternal' => { 'value' => true },
              'LoadBearing' => { 'value' => true }
            }
          }
        }
      end

      def generate_quantities
        {
          'total_area' => 5000.0,
          'total_volume' => 15_000.0,
          'by_type' => {
            'IfcWall' => { 'count' => 120, 'total_area' => 2000.0 },
            'IfcSlab' => { 'count' => 30, 'total_area' => 3000.0 },
            'IfcColumn' => { 'count' => 45, 'total_volume' => 150.0 }
          }
        }
      end

      def generate_classifications
        {
          'Uniclass' => [
            { 'code' => 'Ss_25_10_20', 'name' => 'Walls and partitions' },
            { 'code' => 'Ss_25_20_10', 'name' => 'Floors' }
          ]
        }
      end

      def generate_materials
        {
          'materials' => [
            {
              'name' => 'Concrete C30/37',
              'properties' => { 'density' => 2400, 'strength' => 30 },
              'layers' => []
            },
            {
              'name' => 'Steel S355',
              'properties' => { 'density' => 7850, 'yield_strength' => 355 },
              'layers' => []
            },
            {
              'name' => 'Brick Masonry',
              'properties' => { 'density' => 1800, 'thermal_conductivity' => 0.6 },
              'layers' => []
            }
          ]
        }
      end

      def generate_types
        {
          'IfcWallType' => {
            'count' => 15,
            'types' => [
              { 'name' => 'External Wall 300mm', 'count' => 8 },
              { 'name' => 'Internal Wall 150mm', 'count' => 7 }
            ]
          },
          'IfcSlabType' => {
            'count' => 6,
            'types' => [
              { 'name' => 'Floor Slab 200mm', 'count' => 5 },
              { 'name' => 'Roof Slab 250mm', 'count' => 1 }
            ]
          }
        }
      end

      def print_summary
        puts "\n📊 IFC Upload Demo Summary:"
        puts "  Project: #{@project.name}"
        puts "  IFC Models: #{@ifc_models.size}"

        @ifc_models.each do |model|
          metadata = model.ifc_model_metadata
          puts "\n  Model: #{model.title}"
          puts "    Status: #{model.conversion_status}"
          puts "    Progress: #{model.conversion_progress}%"
          puts "    IFC Version: #{metadata.ifc_version}"
          puts "    Entities: #{metadata.entity_count}"
          puts "    Complexity: #{(metadata.complexity_score * 100).round}%"
          puts "    Warnings: #{metadata.validation_warnings.size}"
          puts "    Duplicate: #{metadata.duplicate? ? 'Yes' : 'No'}"
        end
      end
    end
  end
end

# Run seeder if executed directly
if __FILE__ == $PROGRAM_NAME
  Bim::Seeds::IfcUploadDemoData.seed!
end
