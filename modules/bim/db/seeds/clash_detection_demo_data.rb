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
# Clash Detection Demo Data Seeder
#
# Creates demonstration data for the Clash Detection feature:
# - Demo IFC model with realistic elements
# - Various types of clashes (hard, soft, clearance)
# - Different severity levels and statuses
# - Work packages linked to critical clashes
# - Resolution examples
#
# Usage:
#   rails runner modules/bim/db/seeds/clash_detection_demo_data.rb
#
# Or from Rails console:
#   load 'modules/bim/db/seeds/clash_detection_demo_data.rb'
#

module Bim
  module Seeds
    class ClashDetectionDemoData
      def self.seed!
        new.seed!
      end

      def seed!
        puts "🌱 Seeding Clash Detection demo data..."

        # Find or create demo project
        @project = find_or_create_demo_project
        puts "✓ Using project: #{@project.name}"

        # Find or create IFC model
        @ifc_model = find_or_create_ifc_model
        puts "✓ Using IFC model: #{@ifc_model.title}"

        # Create demo clashes
        @clashes = create_demo_clashes
        puts "✓ Created #{@clashes.size} demo clashes"

        # Create work packages for critical clashes
        @work_packages = create_work_packages
        puts "✓ Created #{@work_packages.size} work packages"

        # Link clashes to work packages
        link_clashes_to_work_packages
        puts "✓ Linked clashes to work packages"

        # Demonstrate resolution workflows
        demonstrate_resolution_workflows
        puts "✓ Demonstrated resolution workflows"

        # Print summary
        print_summary

        puts "\n✅ Clash Detection demo data seeded successfully!"
      end

      private

      def find_or_create_demo_project
        Project.find_or_create_by!(identifier: 'bim-demo') do |p|
          p.name = 'BIM Demo Project'
          p.description = 'Demonstration project for BIM clash detection'
          p.enabled_module_names = %w[bim work_package_tracking]
        end
      end

      def find_or_create_ifc_model
        Bim::IfcModels::IfcModel.find_or_create_by!(title: 'Office Building - Phase 1') do |m|
          m.project = @project
          m.uploader = User.admin.first || User.first
          m.is_default = true

          # Mock metadata with realistic building elements
          m.metadata = {
            'elements' => generate_demo_elements
          }
        end
      end

      def generate_demo_elements
        elements = {}

        # Structural elements (walls, columns, beams)
        (1..15).each do |i|
          elements["wall-#{i}"] = {
            'properties' => {
              'type' => 'IfcWall',
              'name' => "Wall #{i}",
              'LoadBearing' => i <= 8 ? 'True' : 'False',
              'FireRating' => i <= 5 ? '120min' : 'None'
            },
            'geometry' => {
              'hash' => "wall_hash_#{i}",
              'boundingBox' => generate_wall_bbox(i)
            },
            'spatial_structure' => {
              'building' => 'Office Building',
              'storey' => "Level #{(i - 1) / 5 + 1}",
              'space' => "Office #{i}"
            },
            'tags' => i <= 8 ? ['structural', 'load-bearing'] : ['partition']
          }
        end

        # Columns
        (1..8).each do |i|
          elements["column-#{i}"] = {
            'properties' => {
              'type' => 'IfcColumn',
              'name' => "Column C#{i}",
              'LoadBearing' => 'True'
            },
            'geometry' => {
              'hash' => "column_hash_#{i}",
              'boundingBox' => generate_column_bbox(i)
            },
            'spatial_structure' => {
              'building' => 'Office Building',
              'storey' => "Level #{(i - 1) / 4 + 1}",
              'space' => nil
            },
            'tags' => ['structural', 'load-bearing']
          }
        end

        # MEP elements (ducts, pipes)
        (1..10).each do |i|
          elements["duct-#{i}"] = {
            'properties' => {
              'type' => 'IfcFlowSegment',
              'name' => "HVAC Duct #{i}",
              'System' => i <= 5 ? 'Supply Air' : 'Return Air'
            },
            'geometry' => {
              'hash' => "duct_hash_#{i}",
              'boundingBox' => generate_duct_bbox(i)
            },
            'spatial_structure' => {
              'building' => 'Office Building',
              'storey' => "Level #{(i - 1) / 5 + 1}",
              'space' => nil
            },
            'tags' => ['mep', 'hvac']
          }
        end

        (1..8).each do |i|
          elements["pipe-#{i}"] = {
            'properties' => {
              'type' => 'IfcPipeSegment',
              'name' => "Water Pipe #{i}",
              'System' => i <= 4 ? 'Cold Water' : 'Hot Water'
            },
            'geometry' => {
              'hash' => "pipe_hash_#{i}",
              'boundingBox' => generate_pipe_bbox(i)
            },
            'spatial_structure' => {
              'building' => 'Office Building',
              'storey' => "Level #{(i - 1) / 4 + 1}",
              'space' => nil
            },
            'tags' => ['mep', 'plumbing']
          }
        end

        elements
      end

      def generate_wall_bbox(index)
        # Generate overlapping bounding boxes for some walls to create clashes
        base_x = index * 2000
        overlap = (index % 3 == 0) ? 100 : 0 # Some walls overlap

        {
          'min' => [base_x, 0, 0],
          'max' => [base_x + 5000 + overlap, 300, 3500]
        }
      end

      def generate_column_bbox(index)
        {
          'min' => [index * 4000, index * 4000, 0],
          'max' => [index * 4000 + 500, index * 4000 + 500, 3500]
        }
      end

      def generate_duct_bbox(index)
        # Some ducts clash with walls (ceiling height)
        base_z = index <= 3 ? 3200 : 2900 # First 3 are high (potential clashes)

        {
          'min' => [index * 3000, -50, base_z],
          'max' => [index * 3000 + 8000, 650, base_z + 400]
        }
      end

      def generate_pipe_bbox(index)
        {
          'min' => [index * 3500, 0, 2500],
          'max' => [index * 3500 + 6000, 200, 2700]
        }
      end

      def create_demo_clashes
        clashes = []
        detection_run_id = "demo_run_#{Time.current.to_i}"

        # Critical hard clashes (structural conflicts)
        clashes << Bim::Clash.create!(
          ifc_model: @ifc_model,
          element_a_id: 'column-2',
          element_b_id: 'wall-5',
          clash_type: :hard,
          severity: :critical,
          status: :new,
          distance: -150.0,
          overlap_volume: 450.5,
          clash_point: { x: 8000.0, y: 8000.0, z: 1500.0 },
          detected_at: Time.current,
          detection_run_id: detection_run_id,
          description: 'Structural column intersects load-bearing wall'
        )

        clashes << Bim::Clash.create!(
          ifc_model: @ifc_model,
          element_a_id: 'duct-1',
          element_b_id: 'wall-2',
          clash_type: :hard,
          severity: :critical,
          status: :new,
          distance: -80.0,
          overlap_volume: 125.3,
          clash_point: { x: 3000.0, y: 300.0, z: 3300.0 },
          detected_at: Time.current,
          detection_run_id: detection_run_id,
          description: 'HVAC duct penetrates structural wall without proper opening'
        )

        # Major soft clashes (clearance violations)
        clashes << Bim::Clash.create!(
          ifc_model: @ifc_model,
          element_a_id: 'duct-2',
          element_b_id: 'pipe-1',
          clash_type: :soft,
          severity: :major,
          status: :new,
          distance: 35.0,
          clash_point: { x: 6000.0, y: 200.0, z: 2900.0 },
          detected_at: Time.current,
          detection_run_id: detection_run_id,
          description: 'Insufficient clearance between HVAC duct and water pipe'
        )

        clashes << Bim::Clash.create!(
          ifc_model: @ifc_model,
          element_a_id: 'column-3',
          element_b_id: 'duct-3',
          clash_type: :soft,
          severity: :major,
          status: :new,
          distance: 45.0,
          clash_point: { x: 12000.0, y: 12000.0, z: 2950.0 },
          detected_at: Time.current,
          detection_run_id: detection_run_id,
          description: 'HVAC duct too close to structural column'
        )

        # Minor clearance clashes
        clashes << Bim::Clash.create!(
          ifc_model: @ifc_model,
          element_a_id: 'pipe-2',
          element_b_id: 'pipe-3',
          clash_type: :clearance,
          severity: :minor,
          status: :new,
          distance: 60.0,
          clash_point: { x: 7000.0, y: 100.0, z: 2600.0 },
          detected_at: Time.current,
          detection_run_id: detection_run_id,
          description: 'Minimum clearance not met between water pipes'
        )

        clashes << Bim::Clash.create!(
          ifc_model: @ifc_model,
          element_a_id: 'duct-4',
          element_b_id: 'duct-5',
          clash_type: :clearance,
          severity: :minor,
          status: :new,
          distance: 70.0,
          clash_point: { x: 12000.0, y: 250.0, z: 2920.0 },
          detected_at: Time.current,
          detection_run_id: detection_run_id,
          description: 'Ducts from different systems too close'
        )

        # Create some historical clashes (from previous detection run)
        old_run_id = "demo_run_old_#{(Time.current - 7.days).to_i}"

        clashes << Bim::Clash.create!(
          ifc_model: @ifc_model,
          element_a_id: 'wall-7',
          element_b_id: 'wall-8',
          clash_type: :hard,
          severity: :major,
          status: :resolved,
          distance: -50.0,
          overlap_volume: 75.0,
          clash_point: { x: 14000.0, y: 150.0, z: 1800.0 },
          detected_at: 7.days.ago,
          detection_run_id: old_run_id,
          resolution_type: :redesign,
          resolution_comment: 'Wall alignment corrected in updated model',
          resolved_at: 2.days.ago,
          resolved_by: User.admin.first || User.first
        )

        clashes << Bim::Clash.create!(
          ifc_model: @ifc_model,
          element_a_id: 'pipe-5',
          element_b_id: 'wall-10',
          clash_type: :soft,
          severity: :minor,
          status: :approved,
          distance: 40.0,
          clash_point: { x: 17500.0, y: 100.0, z: 2550.0 },
          detected_at: 7.days.ago,
          detection_run_id: old_run_id,
          approval_comment: 'Acceptable clearance per MEP coordinator',
          approved_at: 3.days.ago,
          approved_by: User.admin.first || User.first
        )

        clashes
      end

      def create_work_packages
        type = Type.find_or_create_by!(name: 'Clash Resolution')
        author = User.admin.first || User.first
        work_packages = []

        # Critical clash resolution tasks
        work_packages << WorkPackage.create!(
          project: @project,
          type: type,
          author: author,
          subject: 'Resolve critical column-wall clash on Level 2',
          description: 'Structural column C2 intersects with load-bearing wall. Coordination required between structural and architectural teams.',
          priority: IssuePriority.find_or_create_by!(name: 'Immediate', position: 3)
        )

        work_packages << WorkPackage.create!(
          project: @project,
          type: type,
          author: author,
          subject: 'Coordinate HVAC duct penetration through wall',
          description: 'HVAC duct penetrates structural wall without proper opening. Need to add wall opening or relocate duct.',
          priority: IssuePriority.find_or_create_by!(name: 'Immediate', position: 3)
        )

        # MEP coordination task
        work_packages << WorkPackage.create!(
          project: @project,
          type: type,
          author: author,
          subject: 'MEP coordination - duct and pipe clearances',
          description: 'Multiple clearance violations between HVAC ducts and plumbing. MEP coordination meeting required.',
          priority: IssuePriority.find_or_create_by!(name: 'High', position: 2)
        )

        work_packages
      end

      def link_clashes_to_work_packages
        # Link critical clashes to work packages
        critical_clashes = @clashes.select { |c| c.severity == 'critical' }

        critical_clashes.each_with_index do |clash, index|
          clash.update!(
            work_package: @work_packages[index],
            assigned_to: User.admin.first || User.first,
            status: :active
          )
        end

        # Link major clashes to MEP coordination task
        major_clashes = @clashes.select { |c| c.severity == 'major' && c.status == 'new' }
        major_clashes.each do |clash|
          clash.update!(
            work_package: @work_packages[2],
            status: :active
          )
        end
      end

      def demonstrate_resolution_workflows
        # This method shows different resolution patterns
        # Already done in create_demo_clashes with historical clashes
      end

      def print_summary
        puts "\n📊 Summary:"
        puts "  Project: #{@project.name} (#{@project.identifier})"
        puts "  IFC Model: #{@ifc_model.title}"
        puts "  Total Elements: #{@ifc_model.metadata['elements'].size}"

        puts "\n  Clashes by Type:"
        Bim::Clash.group(:clash_type).count.each do |type, count|
          puts "    - #{type}: #{count}"
        end

        puts "\n  Clashes by Severity:"
        Bim::Clash.group(:severity).count.each do |severity, count|
          puts "    - #{severity}: #{count}"
        end

        puts "\n  Clashes by Status:"
        Bim::Clash.group(:status).count.each do |status, count|
          puts "    - #{status}: #{count}"
        end

        puts "\n  Work Packages:"
        @work_packages.each do |wp|
          clash_count = Bim::Clash.where(work_package: wp).count
          puts "    - #{wp.subject} (#{clash_count} clashes)"
        end

        puts "\n  Example Detection Runs:"
        Bim::Clash.group(:detection_run_id).count.each do |run_id, count|
          puts "    - #{run_id}: #{count} clashes"
        end
      end
    end
  end
end

# Run seeder if executed directly
if __FILE__ == $PROGRAM_NAME
  Bim::Seeds::ClashDetectionDemoData.seed!
end
