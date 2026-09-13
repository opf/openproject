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
# Progress Tracking Demo Data Seeder
#
# Creates demonstration data for the Progress Tracking & Baseline Management feature
#
# Usage:
#   rails runner modules/bim/db/seeds/progress_tracking_demo_data.rb
#

module Bim
  module Seeds
    class ProgressTrackingDemoData
      def self.seed!
        new.seed!
      end

      def seed!
        puts "🌱 Seeding Progress Tracking demo data..."

        @project = find_or_create_demo_project
        puts "✓ Using project: #{@project.name}"

        @model = create_ifc_model
        puts "✓ Created IFC model: #{@model.title}"

        @work_packages = create_work_packages
        puts "✓ Created #{@work_packages.size} work packages"

        @progresses = create_element_progress
        puts "✓ Created #{@progresses.size} element progress records"

        @baselines = create_baselines
        puts "✓ Created #{@baselines.size} baselines"

        print_summary

        puts "\n✅ Progress Tracking demo data seeded successfully!"
      end

      private

      def find_or_create_demo_project
        Project.find_or_create_by!(identifier: 'bim-progress-demo') do |p|
          p.name = 'BIM Progress Tracking Demo'
          p.description = 'Demonstration project for BIM progress tracking and baseline management'
          p.enabled_module_names = %w[bim work_package_tracking]
        end
      end

      def create_ifc_model
        user = User.admin.first || User.first

        Bim::IfcModels::IfcModel.find_or_create_by!(title: 'Commercial Building') do |m|
          m.project = @project
          m.uploader = user
          m.is_default = true
          m.metadata = {
            'elements' => {
              # Foundation elements
              'foundation-1' => { 'properties' => { 'type' => 'IfcFootingFoundation', 'name' => 'Foundation A' } },
              'foundation-2' => { 'properties' => { 'type' => 'IfcFootingFoundation', 'name' => 'Foundation B' } },

              # Structural elements
              'column-1' => { 'properties' => { 'type' => 'IfcColumn', 'name' => 'Column A1' } },
              'column-2' => { 'properties' => { 'type' => 'IfcColumn', 'name' => 'Column A2' } },
              'column-3' => { 'properties' => { 'type' => 'IfcColumn', 'name' => 'Column B1' } },
              'column-4' => { 'properties' => { 'type' => 'IfcColumn', 'name' => 'Column B2' } },

              # Wall elements
              'wall-ext-1' => { 'properties' => { 'type' => 'IfcWall', 'name' => 'Exterior Wall North' } },
              'wall-ext-2' => { 'properties' => { 'type' => 'IfcWall', 'name' => 'Exterior Wall South' } },
              'wall-int-1' => { 'properties' => { 'type' => 'IfcWall', 'name' => 'Interior Wall 1' } },
              'wall-int-2' => { 'properties' => { 'type' => 'IfcWall', 'name' => 'Interior Wall 2' } },

              # Doors and windows
              'door-main' => { 'properties' => { 'type' => 'IfcDoor', 'name' => 'Main Entrance' } },
              'door-1' => { 'properties' => { 'type' => 'IfcDoor', 'name' => 'Office Door 1' } },
              'door-2' => { 'properties' => { 'type' => 'IfcDoor', 'name' => 'Office Door 2' } },
              'window-1' => { 'properties' => { 'type' => 'IfcWindow', 'name' => 'Window Front 1' } },
              'window-2' => { 'properties' => { 'type' => 'IfcWindow', 'name' => 'Window Front 2' } },
              'window-3' => { 'properties' => { 'type' => 'IfcWindow', 'name' => 'Window Side 1' } },

              # Roof elements
              'roof-1' => { 'properties' => { 'type' => 'IfcRoof', 'name' => 'Main Roof Section' } },
              'roof-2' => { 'properties' => { 'type' => 'IfcRoof', 'name' => 'Canopy' } }
            }
          }
        end
      end

      def create_work_packages
        user = User.admin.first || User.first
        type = Type.first || create(:type)
        status_new = Status.find_by(name: 'New') || create(:status, name: 'New')
        status_progress = Status.find_by(name: 'In Progress') || create(:status, name: 'In Progress')
        status_done = Status.find_by(name: 'Done', is_closed: true) || create(:status, name: 'Done', is_closed: true)

        wps = []

        wps << WorkPackage.create!(
          project: @project,
          subject: 'Foundation Work',
          type: type,
          status: status_done,
          author: user,
          done_ratio: 100
        )

        wps << WorkPackage.create!(
          project: @project,
          subject: 'Structural Columns',
          type: type,
          status: status_progress,
          author: user,
          done_ratio: 75
        )

        wps << WorkPackage.create!(
          project: @project,
          subject: 'Exterior Walls',
          type: type,
          status: status_progress,
          author: user,
          done_ratio: 60
        )

        wps << WorkPackage.create!(
          project: @project,
          subject: 'Interior Walls',
          type: type,
          status: status_progress,
          author: user,
          done_ratio: 40
        )

        wps << WorkPackage.create!(
          project: @project,
          subject: 'Doors and Windows',
          type: type,
          status: status_new,
          author: user,
          done_ratio: 25
        )

        wps << WorkPackage.create!(
          project: @project,
          subject: 'Roof Installation',
          type: type,
          status: status_new,
          author: user,
          done_ratio: 0
        )

        wps
      end

      def create_element_progress
        user = User.admin.first || User.first
        progresses = []

        # Foundation - Completed
        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'foundation-1',
          element_type: 'IfcFootingFoundation',
          element_name: 'Foundation A',
          status: :completed,
          percent_complete: 100,
          work_package: @work_packages[0],
          planned_start: 30.days.ago.to_date,
          planned_finish: 20.days.ago.to_date,
          actual_start: 30.days.ago.to_date,
          actual_finish: 20.days.ago.to_date,
          updated_by: user
        )

        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'foundation-2',
          element_type: 'IfcFootingFoundation',
          element_name: 'Foundation B',
          status: :completed,
          percent_complete: 100,
          work_package: @work_packages[0],
          planned_start: 30.days.ago.to_date,
          planned_finish: 20.days.ago.to_date,
          actual_start: 29.days.ago.to_date,
          actual_finish: 19.days.ago.to_date, # Ahead of schedule
          updated_by: user
        )

        # Columns - In Progress (75%)
        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'column-1',
          element_type: 'IfcColumn',
          element_name: 'Column A1',
          status: :completed,
          percent_complete: 100,
          work_package: @work_packages[1],
          actual_start: 18.days.ago.to_date,
          actual_finish: 12.days.ago.to_date,
          updated_by: user
        )

        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'column-2',
          element_type: 'IfcColumn',
          element_name: 'Column A2',
          status: :completed,
          percent_complete: 100,
          work_package: @work_packages[1],
          actual_start: 18.days.ago.to_date,
          actual_finish: 11.days.ago.to_date,
          updated_by: user
        )

        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'column-3',
          element_type: 'IfcColumn',
          element_name: 'Column B1',
          status: :in_progress,
          percent_complete: 75,
          work_package: @work_packages[1],
          actual_start: 10.days.ago.to_date,
          updated_by: user
        )

        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'column-4',
          element_type: 'IfcColumn',
          element_name: 'Column B2',
          status: :in_progress,
          percent_complete: 25,
          work_package: @work_packages[1],
          actual_start: 5.days.ago.to_date,
          updated_by: user
        )

        # Exterior Walls - In Progress (60%)
        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'wall-ext-1',
          element_type: 'IfcWall',
          element_name: 'Exterior Wall North',
          status: :in_progress,
          percent_complete: 80,
          work_package: @work_packages[2],
          planned_start: 15.days.ago.to_date,
          planned_finish: 5.days.from_now.to_date,
          actual_start: 15.days.ago.to_date,
          updated_by: user
        )

        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'wall-ext-2',
          element_type: 'IfcWall',
          element_name: 'Exterior Wall South',
          status: :in_progress,
          percent_complete: 40,
          work_package: @work_packages[2],
          planned_start: 10.days.ago.to_date,
          planned_finish: 10.days.from_now.to_date,
          actual_start: 12.days.ago.to_date, # Started late
          updated_by: user
        )

        # Interior Walls - In Progress (40%)
        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'wall-int-1',
          element_type: 'IfcWall',
          element_name: 'Interior Wall 1',
          status: :in_progress,
          percent_complete: 60,
          work_package: @work_packages[3],
          actual_start: 5.days.ago.to_date,
          updated_by: user
        )

        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'wall-int-2',
          element_type: 'IfcWall',
          element_name: 'Interior Wall 2',
          status: :in_progress,
          percent_complete: 20,
          work_package: @work_packages[3],
          actual_start: 2.days.ago.to_date,
          updated_by: user
        )

        # Doors & Windows - Minimal Progress (25%)
        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'door-main',
          element_type: 'IfcDoor',
          element_name: 'Main Entrance',
          status: :in_progress,
          percent_complete: 50,
          work_package: @work_packages[4],
          actual_start: 1.day.ago.to_date,
          updated_by: user
        )

        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'door-1',
          element_type: 'IfcDoor',
          element_name: 'Office Door 1',
          status: :planned,
          percent_complete: 0,
          work_package: @work_packages[4],
          updated_by: user
        )

        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'window-1',
          element_type: 'IfcWindow',
          element_name: 'Window Front 1',
          status: :in_progress,
          percent_complete: 25,
          work_package: @work_packages[4],
          actual_start: 1.day.ago.to_date,
          updated_by: user
        )

        # Roof - Not Started
        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'roof-1',
          element_type: 'IfcRoof',
          element_name: 'Main Roof Section',
          status: :planned,
          percent_complete: 0,
          work_package: @work_packages[5],
          planned_start: 5.days.from_now.to_date,
          planned_finish: 20.days.from_now.to_date,
          updated_by: user
        )

        progresses << Bim::ElementProgress.create!(
          ifc_model: @model,
          element_id: 'roof-2',
          element_type: 'IfcRoof',
          element_name: 'Canopy',
          status: :planned,
          percent_complete: 0,
          work_package: @work_packages[5],
          planned_start: 10.days.from_now.to_date,
          planned_finish: 25.days.from_now.to_date,
          updated_by: user
        )

        progresses
      end

      def create_baselines
        user = User.admin.first || User.first
        baselines = []

        # Baseline 1: Week 1 (after foundation)
        baseline1 = Bim::ProgressBaseline.create!(
          ifc_model: @model,
          name: 'Week 1 - Foundation Complete',
          description: 'Progress snapshot after foundation completion',
          snapshot_date: 20.days.ago.to_date,
          created_by: user,
          is_current: false
        )

        # Manually set snapshot data for week 1 (foundation only)
        Bim::ElementProgress.create!(
          ifc_model: @model,
          baseline: baseline1,
          element_id: 'foundation-1',
          element_type: 'IfcFootingFoundation',
          element_name: 'Foundation A',
          status: :completed,
          percent_complete: 100
        )

        Bim::ElementProgress.create!(
          ifc_model: @model,
          baseline: baseline1,
          element_id: 'foundation-2',
          element_type: 'IfcFootingFoundation',
          element_name: 'Foundation B',
          status: :completed,
          percent_complete: 100
        )

        baseline1.update!(
          total_elements: 2,
          completed_elements: 2,
          overall_progress: 100.0
        )

        baselines << baseline1

        # Baseline 2: Week 2 (columns started, marked as current)
        baseline2 = Bim::ProgressBaseline.create!(
          ifc_model: @model,
          name: 'Week 2 - Columns Started',
          description: 'Current baseline with structural work underway',
          snapshot_date: 10.days.ago.to_date,
          created_by: user,
          is_current: true
        )

        baseline2.create_snapshot!
        baselines << baseline2

        baselines
      end

      def print_summary
        service = Bim::Progress::TrackingService.new(ifc_model: @model)
        stats = service.calculate_model_progress

        puts "\n📊 Summary:"
        puts "  Project: #{@project.name}"
        puts "  Model: #{@model.title}"
        puts "\n  Work Packages: #{@work_packages.size}"
        @work_packages.each do |wp|
          puts "    - #{wp.subject} (#{wp.done_ratio}%)"
        end
        puts "\n  Progress Statistics:"
        puts "    Total Elements: #{stats[:total_elements]}"
        puts "    Completed: #{stats[:completed_elements]}"
        puts "    In Progress: #{stats[:in_progress_elements]}"
        puts "    Planned: #{stats[:planned_elements]}"
        puts "    Overall Progress: #{stats[:overall_progress]}%"
        puts "    Delayed: #{stats[:delayed_count]}"
        puts "    Ahead: #{stats[:ahead_count]}"
        puts "\n  Baselines: #{@baselines.size}"
        @baselines.each do |baseline|
          puts "    - #{baseline.name} (#{baseline.overall_progress}%)#{baseline.is_current ? ' [CURRENT]' : ''}"
        end
      end
    end
  end
end

# Run seeder if executed directly
if __FILE__ == $PROGRAM_NAME
  Bim::Seeds::ProgressTrackingDemoData.seed!
end
