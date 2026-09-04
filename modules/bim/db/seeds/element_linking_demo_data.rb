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
# Element Linking Demo Data Seeder
#
# Creates demonstration data for the Element Linking feature:
# - Demo work packages for different scenarios
# - Element link templates
# - Sample element links
# - Various relationship types and statuses
#
# Usage:
#   rails runner modules/bim/db/seeds/element_linking_demo_data.rb
#
# Or from Rails console:
#   load 'modules/bim/db/seeds/element_linking_demo_data.rb'
#

module Bim
  module Seeds
    class ElementLinkingDemoData
      def self.seed!
        new.seed!
      end

      def seed!
        puts "🌱 Seeding Element Linking demo data..."

        # Find or create demo project
        @project = find_or_create_demo_project
        puts "✓ Using project: #{@project.name}"

        # Find or create IFC model
        @ifc_model = find_or_create_ifc_model
        puts "✓ Using IFC model: #{@ifc_model.title}"

        # Create work packages
        @work_packages = create_work_packages
        puts "✓ Created #{@work_packages.size} work packages"

        # Create link templates
        @templates = create_link_templates
        puts "✓ Created #{@templates.size} link templates"

        # Create sample links
        @links = create_element_links
        puts "✓ Created #{@links.size} element links"

        # Print summary
        print_summary

        puts "\n✅ Element Linking demo data seeded successfully!"
      end

      private

      def find_or_create_demo_project
        Project.find_or_create_by!(identifier: 'bim-demo') do |p|
          p.name = 'BIM Demo Project'
          p.description = 'Demonstration project for BIM element linking'
          p.enabled_module_names = %w[bim work_package_tracking]
        end
      end

      def find_or_create_ifc_model
        Bim::IfcModels::IfcModel.find_or_create_by!(title: 'Demo Building') do |m|
          m.project = @project
          m.uploader = User.admin.first || User.first
          m.is_default = true

          # Mock metadata for demo purposes
          m.metadata = {
            'elements' => generate_demo_elements
          }
        end
      end

      def generate_demo_elements
        elements = {}

        # Generate walls
        (1..10).each do |i|
          elements["wall-#{i}"] = {
            'properties' => {
              'type' => 'IfcWall',
              'name' => "Wall #{i}",
              'LoadBearing' => i.odd? ? 'True' : 'False'
            },
            'spatial_structure' => {
              'building' => 'Building A',
              'storey' => "Level #{(i - 1) / 3 + 1}",
              'space' => "Room #{i}"
            },
            'geometry' => {
              'hash' => "wall_hash_#{i}"
            },
            'classifications' => [
              { 'system' => 'Uniclass', 'code' => 'Ss_25_10_20' }
            ],
            'tags' => i.odd? ? ['structural', 'external'] : ['non-structural', 'internal']
          }
        end

        # Generate doors
        (1..5).each do |i|
          elements["door-#{i}"] = {
            'properties' => {
              'type' => 'IfcDoor',
              'name' => "Door #{i}",
              'FireRating' => i <= 2 ? '60min' : 'None'
            },
            'spatial_structure' => {
              'building' => 'Building A',
              'storey' => "Level #{(i - 1) / 2 + 1}",
              'space' => "Room #{i}"
            },
            'geometry' => {
              'hash' => "door_hash_#{i}"
            },
            'tags' => i <= 2 ? ['fire-rated'] : ['standard']
          }
        end

        # Generate columns
        (1..4).each do |i|
          elements["column-#{i}"] = {
            'properties' => {
              'type' => 'IfcColumn',
              'name' => "Column #{i}",
              'LoadBearing' => 'True'
            },
            'spatial_structure' => {
              'building' => 'Building A',
              'storey' => "Level #{i}",
              'space' => nil
            },
            'geometry' => {
              'hash' => "column_hash_#{i}"
            },
            'classifications' => [
              { 'system' => 'Uniclass', 'code' => 'Ss_25_10_30' }
            ],
            'tags' => ['structural']
          }
        end

        elements
      end

      def create_work_packages
        type = Type.find_or_create_by!(name: 'Task')
        author = User.admin.first || User.first

        work_packages = []

        # Defect tracking work package
        work_packages << WorkPackage.create!(
          project: @project,
          type: type,
          author: author,
          subject: 'Structural wall cracks on Level 1',
          description: 'Several walls showing stress cracks that need inspection',
          priority: IssuePriority.find_or_create_by!(name: 'High', position: 2)
        )

        # Maintenance work package
        work_packages << WorkPackage.create!(
          project: @project,
          type: type,
          author: author,
          subject: 'Fire door inspection and replacement',
          description: 'Inspect all fire-rated doors and replace as needed',
          priority: IssuePriority.find_or_create_by!(name: 'Normal', position: 1)
        )

        # Construction work package
        work_packages << WorkPackage.create!(
          project: @project,
          type: type,
          author: author,
          subject: 'Column reinforcement',
          description: 'Add additional reinforcement to structural columns',
          priority: IssuePriority.find_or_create_by!(name: 'High', position: 2)
        )

        # Monitoring work package
        work_packages << WorkPackage.create!(
          project: @project,
          type: type,
          author: author,
          subject: 'Structural monitoring',
          description: 'Ongoing monitoring of load-bearing elements',
          priority: IssuePriority.find_or_create_by!(name: 'Low', position: 0)
        )

        work_packages
      end

      def create_link_templates
        author = User.admin.first || User.first
        templates = []

        # Structural elements template
        templates << Bim::LinkTemplate.create!(
          name: 'Structural Elements',
          description: 'All load-bearing structural elements',
          relationship_type: :responsible_for,
          author: author,
          project: @project,
          element_filters: {
            'types' => ['IfcWall', 'IfcColumn'],
            'properties' => {
              'LoadBearing' => 'True'
            },
            'tags' => ['structural']
          },
          auto_apply: false,
          public: false
        )

        # Fire-rated elements template
        templates << Bim::LinkTemplate.create!(
          name: 'Fire-Rated Elements',
          description: 'Elements with fire rating requirements',
          relationship_type: :observes,
          author: author,
          project: @project,
          element_filters: {
            'types' => ['IfcDoor'],
            'properties' => {
              'FireRating' => { 'ne' => 'None' }
            },
            'tags' => ['fire-rated']
          },
          auto_apply: false,
          public: false
        )

        # Level 1 elements template
        templates << Bim::LinkTemplate.create!(
          name: 'Level 1 Elements',
          description: 'All elements on Level 1',
          relationship_type: :related_to,
          author: author,
          project: @project,
          element_filters: {
            'locations' => {
              'storey' => ['Level 1']
            }
          },
          auto_apply: false,
          public: false
        )

        templates
      end

      def create_element_links
        links = []

        # Links for structural defects work package
        wp_defects = @work_packages[0]
        ['wall-1', 'wall-2', 'wall-3'].each do |element_id|
          links << Bim::ElementLink.create!(
            work_package: wp_defects,
            ifc_model: @ifc_model,
            element_id: element_id,
            relationship_type: :affected_by,
            status: :active,
            element_properties: @ifc_model.metadata.dig('elements', element_id)
          )
        end

        # Links for fire door maintenance work package
        wp_doors = @work_packages[1]
        ['door-1', 'door-2'].each_with_index do |element_id, index|
          links << Bim::ElementLink.create!(
            work_package: wp_doors,
            ifc_model: @ifc_model,
            element_id: element_id,
            relationship_type: :responsible_for,
            status: index == 0 ? :completed : :active,
            template: @templates[1], # Fire-rated template
            element_properties: @ifc_model.metadata.dig('elements', element_id)
          )
        end

        # Links for column reinforcement work package
        wp_columns = @work_packages[2]
        ['column-1', 'column-2', 'column-3', 'column-4'].each do |element_id|
          links << Bim::ElementLink.create!(
            work_package: wp_columns,
            ifc_model: @ifc_model,
            element_id: element_id,
            relationship_type: :responsible_for,
            status: :active,
            template: @templates[0], # Structural template
            element_properties: @ifc_model.metadata.dig('elements', element_id)
          )
        end

        # Links for monitoring work package
        wp_monitoring = @work_packages[3]
        ['wall-1', 'wall-4', 'wall-7', 'column-1', 'column-2'].each do |element_id|
          links << Bim::ElementLink.create!(
            work_package: wp_monitoring,
            ifc_model: @ifc_model,
            element_id: element_id,
            relationship_type: :observes,
            status: :active,
            element_properties: @ifc_model.metadata.dig('elements', element_id)
          )
        end

        links
      end

      def print_summary
        puts "\n📊 Summary:"
        puts "  Project: #{@project.name} (#{@project.identifier})"
        puts "  IFC Model: #{@ifc_model.title}"
        puts "  Total Elements: #{@ifc_model.metadata['elements'].size}"
        puts "\n  Work Packages:"
        @work_packages.each do |wp|
          link_count = Bim::ElementLink.where(work_package: wp).count
          puts "    - #{wp.subject} (#{link_count} links)"
        end
        puts "\n  Templates:"
        @templates.each do |template|
          puts "    - #{template.name} (#{template.relationship_type})"
        end
        puts "\n  Links by Relationship Type:"
        Bim::ElementLink.group(:relationship_type).count.each do |type, count|
          puts "    - #{type}: #{count}"
        end
        puts "\n  Links by Status:"
        Bim::ElementLink.group(:status).count.each do |status, count|
          puts "    - #{status}: #{count}"
        end
      end
    end
  end
end

# Run seeder if executed directly
if __FILE__ == $PROGRAM_NAME
  Bim::Seeds::ElementLinkingDemoData.seed!
end
