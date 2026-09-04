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
  ##
  # Dashboard model for BIM project dashboards
  #
  # Represents a configurable dashboard containing multiple widgets
  # displaying BIM metrics, charts, and KPIs.
  #
  # Example:
  #   dashboard = Bim::Dashboard.create!(
  #     project: project,
  #     user: user,
  #     name: 'Project Overview',
  #     is_default: true
  #   )
  #
  #   dashboard.widgets.create!(
  #     widget_type: :clash_summary,
  #     position: { x: 0, y: 0 },
  #     size: { width: 6, height: 4 }
  #   )
  #
  class Dashboard < ApplicationRecord
    self.table_name = 'bim_dashboards'

    belongs_to :project, class_name: 'Project'
    belongs_to :user, class_name: 'User', optional: true

    has_many :widgets,
             class_name: 'Bim::DashboardWidget',
             foreign_key: 'dashboard_id',
             dependent: :destroy

    # Validations
    validates :name, presence: true, length: { maximum: 255 }
    validates :project_id, presence: true
    validate :only_one_default_per_project, if: :is_default?

    # Scopes
    scope :for_project, ->(project) { where(project: project) }
    scope :for_user, ->(user) { where(user: user) }
    scope :default_dashboards, -> { where(is_default: true) }
    scope :public_dashboards, -> { where(is_public: true) }
    scope :recent, -> { order(updated_at: :desc) }

    ##
    # Get or create the default dashboard for a project
    #
    # @param project [Project]
    # @return [Dashboard]
    #
    def self.default_for_project(project)
      find_or_create_by!(project: project, is_default: true) do |dashboard|
        dashboard.name = 'Default BIM Dashboard'
        dashboard.description = 'Automatically generated default dashboard'
        dashboard.is_public = true
        dashboard.layout_config = default_layout_config
      end
    end

    ##
    # Render all widgets with their current data
    #
    # @param force_refresh [Boolean] Force data refresh even if cached
    # @return [Array<Hash>] Widget data
    #
    def render_widgets(force_refresh: false)
      widgets.map do |widget|
        {
          id: widget.id,
          type: widget.widget_type,
          title: widget.title || widget.default_title,
          position: widget.position,
          size: widget.size,
          config: widget.config,
          data: widget.fetch_data(force_refresh: force_refresh),
          last_updated: widget.cached_at || widget.updated_at
        }
      end
    end

    ##
    # Get dashboard metrics summary
    #
    # @return [Hash]
    #
    def metrics_summary
      {
        total_widgets: widgets.count,
        widget_types: widgets.group(:widget_type).count,
        last_refresh: widgets.maximum(:cached_at),
        has_stale_data: widgets.where('cached_at < ?', 1.hour.ago).exists?
      }
    end

    ##
    # Refresh all widget caches
    #
    def refresh_all_widgets!
      widgets.each(&:refresh_cache!)
    end

    ##
    # Clone dashboard for another user or project
    #
    # @param user [User, nil]
    # @param project [Project, nil]
    # @return [Dashboard]
    #
    def clone_for(user: nil, project: nil)
      new_dashboard = dup
      new_dashboard.user = user if user
      new_dashboard.project = project if project
      new_dashboard.is_default = false
      new_dashboard.name = "#{name} (Copy)"
      new_dashboard.save!

      # Clone all widgets
      widgets.each do |widget|
        new_widget = widget.dup
        new_widget.dashboard = new_dashboard
        new_widget.cached_data = {}
        new_widget.cached_at = nil
        new_widget.save!
      end

      new_dashboard
    end

    ##
    # Export dashboard configuration (for templates)
    #
    # @return [Hash]
    #
    def export_config
      {
        name: name,
        description: description,
        layout_config: layout_config,
        settings: settings,
        widgets: widgets.map(&:export_config)
      }
    end

    ##
    # Import dashboard from configuration
    #
    # @param config [Hash]
    # @param project [Project]
    # @param user [User, nil]
    # @return [Dashboard]
    #
    def self.import_config(config, project:, user: nil)
      dashboard = create!(
        project: project,
        user: user,
        name: config['name'],
        description: config['description'],
        layout_config: config['layout_config'] || {},
        settings: config['settings'] || {}
      )

      config['widgets']&.each do |widget_config|
        DashboardWidget.import_config(widget_config, dashboard: dashboard)
      end

      dashboard
    end

    ##
    # Check if dashboard is accessible by user
    #
    # @param user [User]
    # @return [Boolean]
    #
    def accessible_by?(user)
      return true if is_public
      return true if self.user_id == user.id
      return true if user.admin?

      false
    end

    ##
    # Get widget by type
    #
    # @param type [Symbol]
    # @return [DashboardWidget, nil]
    #
    def widget_by_type(type)
      widgets.find_by(widget_type: type)
    end

    ##
    # Check if dashboard has widget type
    #
    # @param type [Symbol]
    # @return [Boolean]
    #
    def has_widget?(type)
      widgets.exists?(widget_type: type)
    end

    ##
    # Add widget to dashboard
    #
    # @param type [Symbol]
    # @param position [Hash]
    # @param size [Hash]
    # @param config [Hash]
    # @return [DashboardWidget]
    #
    def add_widget(type, position: {}, size: {}, config: {})
      widgets.create!(
        widget_type: type,
        position: position.presence || auto_position,
        size: size.presence || DashboardWidget.default_size_for(type),
        config: config
      )
    end

    ##
    # Calculate next available position for widget
    #
    # @return [Hash]
    #
    def auto_position
      # Simple algorithm: find first available spot in grid
      max_y = widgets.maximum("(position->>'y')::int") || 0
      { x: 0, y: max_y + 1 }
    end

    private

    def only_one_default_per_project
      existing = self.class.where(project: project, is_default: true)
                     .where.not(id: id)
                     .exists?

      if existing
        errors.add(:is_default, 'Only one default dashboard allowed per project')
      end
    end

    def self.default_layout_config
      {
        cols: 12,
        rowHeight: 100,
        margins: [10, 10],
        draggable: true,
        resizable: true
      }
    end
  end
end
