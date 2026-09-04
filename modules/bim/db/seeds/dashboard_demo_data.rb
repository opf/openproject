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
# BIM Dashboard Demo Data Seeder
#
# Creates demonstration data for the BIM Dashboards & Reporting feature
#
# Usage:
#   rails runner modules/bim/db/seeds/dashboard_demo_data.rb
#

module Bim
  module Seeds
    class DashboardDemoData
      def self.seed!
        new.seed!
      end

      def seed!
        puts "🌱 Seeding BIM Dashboard demo data..."

        @project = find_or_create_demo_project
        puts "✓ Using project: #{@project.name}"

        @user = User.admin.first || User.first
        puts "✓ Using user: #{@user.name}"

        @dashboard = create_dashboard
        puts "✓ Created dashboard: #{@dashboard.name}"

        @widgets = create_widgets
        puts "✓ Created #{@widgets.size} widgets"

        refresh_widget_data
        puts "✓ Refreshed all widget data"

        print_summary

        puts "\n✅ BIM Dashboard demo data seeded successfully!"
      end

      private

      def find_or_create_demo_project
        Project.find_or_create_by!(identifier: 'bim-dashboard-demo') do |p|
          p.name = 'BIM Dashboard Demo'
          p.description = 'Demonstration project for BIM dashboards and reporting'
          p.enabled_module_names = %w[bim work_package_tracking]
        end
      end

      def create_dashboard
        Dashboard.find_or_create_by!(project: @project, name: 'Project Overview Dashboard') do |dashboard|
          dashboard.user = @user
          dashboard.description = 'Comprehensive BIM project metrics and KPIs'
          dashboard.is_default = true
          dashboard.is_public = true
          dashboard.layout_config = {
            cols: 12,
            rowHeight: 100,
            margins: [10, 10],
            draggable: true,
            resizable: true
          }
          dashboard.settings = {
            refresh_interval: 300,
            theme: 'light'
          }
        end
      end

      def create_widgets
        widgets = []

        # Row 1: KPI Cards
        widgets << create_widget(
          type: :model_count,
          title: 'IFC Models',
          position: { x: 0, y: 0 },
          size: { width: 3, height: 3 }
        )

        widgets << create_widget(
          type: :kpi_card,
          title: 'Active Clashes',
          position: { x: 3, y: 0 },
          size: { width: 3, height: 3 },
          config: { metric_type: 'clashes' }
        )

        widgets << create_widget(
          type: :kpi_card,
          title: 'Overall Progress',
          position: { x: 6, y: 0 },
          size: { width: 3, height: 3 },
          config: { metric_type: 'progress' }
        )

        widgets << create_widget(
          type: :work_package_summary,
          title: 'Work Packages',
          position: { x: 9, y: 0 },
          size: { width: 3, height: 3 }
        )

        # Row 2: Charts
        widgets << create_widget(
          type: :progress_chart,
          title: 'Construction Progress',
          position: { x: 0, y: 3 },
          size: { width: 6, height: 4 }
        )

        widgets << create_widget(
          type: :clash_summary,
          title: 'Clash Detection Summary',
          position: { x: 6, y: 3 },
          size: { width: 6, height: 4 }
        )

        # Row 3: Trends and Activity
        widgets << create_widget(
          type: :issue_trend,
          title: 'BCF Issue Trends (30 days)',
          position: { x: 0, y: 7 },
          size: { width: 6, height: 4 },
          config: { date_range: { days: 30 } }
        )

        widgets << create_widget(
          type: :recent_activity,
          title: 'Recent BIM Activity',
          position: { x: 6, y: 7 },
          size: { width: 6, height: 4 }
        )

        # Row 4: Additional Metrics
        widgets << create_widget(
          type: :discipline_breakdown,
          title: 'Elements by Discipline',
          position: { x: 0, y: 11 },
          size: { width: 6, height: 3 }
        )

        widgets << create_widget(
          type: :resolution_rate,
          title: 'Resolution Rates',
          position: { x: 6, y: 11 },
          size: { width: 6, height: 3 }
        )

        widgets
      end

      def create_widget(type:, title:, position:, size:, config: {})
        DashboardWidget.find_or_create_by!(
          dashboard: @dashboard,
          widget_type: type,
          position: position
        ) do |widget|
          widget.title = title
          widget.size = size
          widget.config = config
          widget.refresh_interval = 300 # 5 minutes
        end
      end

      def refresh_widget_data
        @widgets.each do |widget|
          widget.refresh_cache!
        rescue StandardError => e
          puts "  ⚠️  Error refreshing #{widget.title}: #{e.message}"
        end
      end

      def print_summary
        puts "\n📊 Dashboard Summary:"
        puts "  Dashboard: #{@dashboard.name}"
        puts "  Widgets: #{@widgets.size}"
        puts "\n  Widget Breakdown:"
        @dashboard.widgets.group_by(&:widget_type).each do |type, widgets|
          puts "    #{type}: #{widgets.size}"
        end

        metrics = @dashboard.metrics_summary
        puts "\n  Metrics:"
        puts "    Total Widgets: #{metrics[:total_widgets]}"
        puts "    Has Stale Data: #{metrics[:has_stale_data]}"
        puts "    Last Refresh: #{metrics[:last_refresh] || 'Never'}"
      end
    end
  end
end

# Run seeder if executed directly
if __FILE__ == $PROGRAM_NAME
  Bim::Seeds::DashboardDemoData.seed!
end
