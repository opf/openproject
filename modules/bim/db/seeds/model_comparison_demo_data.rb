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
# Model Comparison Demo Data Seeder
#
# Creates demonstration data for the Model Comparison feature
#
# Usage:
#   rails runner modules/bim/db/seeds/model_comparison_demo_data.rb
#

module Bim
  module Seeds
    class ModelComparisonDemoData
      def self.seed!
        new.seed!
      end

      def seed!
        puts "🌱 Seeding Model Comparison demo data..."

        @project = find_or_create_demo_project
        puts "✓ Using project: #{@project.name}"

        @models = create_model_versions
        puts "✓ Created #{@models.size} model versions"

        @comparisons = create_comparisons
        puts "✓ Created #{@comparisons.size} comparisons"

        print_summary

        puts "\n✅ Model Comparison demo data seeded successfully!"
      end

      private

      def find_or_create_demo_project
        Project.find_or_create_by!(identifier: 'bim-demo') do |p|
          p.name = 'BIM Demo Project'
          p.description = 'Demonstration project for BIM model comparison'
          p.enabled_module_names = %w[bim work_package_tracking]
        end
      end

      def create_model_versions
        user = User.admin.first || User.first

        v1 = Bim::IfcModels::IfcModel.find_or_create_by!(title: 'Office Building V1') do |m|
          m.project = @project
          m.uploader = user
          m.is_default = false
          m.metadata = {
            'elements' => {
              'wall-1' => { 'properties' => { 'type' => 'IfcWall', 'name' => 'North Wall', 'height' => '3000' } },
              'wall-2' => { 'properties' => { 'type' => 'IfcWall', 'name' => 'South Wall', 'height' => '3000' } },
              'door-1' => { 'properties' => { 'type' => 'IfcDoor', 'name' => 'Main Entrance' } }
            }
          }
        end

        v2 = Bim::IfcModels::IfcModel.find_or_create_by!(title: 'Office Building V2') do |m|
          m.project = @project
          m.uploader = user
          m.is_default = true
          m.metadata = {
            'elements' => {
              'wall-1' => { 'properties' => { 'type' => 'IfcWall', 'name' => 'North Wall', 'height' => '3500' } }, # Modified
              'wall-2' => { 'properties' => { 'type' => 'IfcWall', 'name' => 'South Wall', 'height' => '3000' } }, # Unchanged
              'window-1' => { 'properties' => { 'type' => 'IfcWindow', 'name' => 'Window 1' } } # Added
              # door-1 removed
            }
          }
        end

        [v1, v2]
      end

      def create_comparisons
        user = User.admin.first || User.first
        comparisons = []

        # Create V1 → V2 comparison
        service = Bim::Comparison::CompareService.new(
          model1: @models[0],
          model2: @models[1],
          options: { user: user }
        )

        result = service.call
        comparison = result.result
        comparison.update!(
          name: 'Initial Design vs Updated Version',
          description: 'Comparison of initial office building design to updated version with windows'
        )
        comparisons << comparison

        # Approve the comparison
        comparison.approve!(user: user, comment: 'Changes approved - proceed with updated design')

        comparisons
      end

      def print_summary
        puts "\n📊 Summary:"
        puts "  Project: #{@project.name}"
        puts "  Models: #{@models.map(&:title).join(', ')}"
        puts "\n  Comparisons:"
        @comparisons.each do |comp|
          puts "    - #{comp.name}"
          puts "      Added: #{comp.added_count}, Deleted: #{comp.deleted_count}, Modified: #{comp.modified_count}"
          puts "      Status: #{comp.status}"
        end
      end
    end
  end
end

# Run seeder if executed directly
if __FILE__ == $PROGRAM_NAME
  Bim::Seeds::ModelComparisonDemoData.seed!
end
