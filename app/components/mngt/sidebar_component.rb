# frozen_string_literal: true

class Mngt::SidebarComponent < ApplicationComponent
  PALETTE = %w[#7c3aed #2563eb #059669 #dc2626 #d97706 #0891b2 #be185d #65a30d].freeze

  ASSIGNED_FILTER = CGI.escape(
    { "f" => [{ "n" => "assignee", "o" => "=", "v" => ["me"] }, { "n" => "status", "o" => "o", "v" => [] }] }.to_json
  ).freeze

  OVERDUE_FILTER = CGI.escape(
    { "f" => [{ "n" => "dueDate", "o" => "<t+", "v" => ["0"] }, { "n" => "status", "o" => "o", "v" => [] }] }.to_json
  ).freeze

  def initialize(current_user:, current_project: nil)
    super()
    @current_user = current_user
    @current_project = current_project
  end

  def notification_count
    @notification_count ||= Notification.recipient(@current_user).where(read_ian: false).count
  rescue StandardError
    0
  end

  def favorite_projects
    @favorite_projects ||= Favorite
      .where(user: @current_user, favorited_type: "Project")
      .includes(:favorited)
      .filter_map(&:favorited)
      .select { |p| p.is_a?(Project) && p.active? }
  rescue StandardError
    []
  end

  # Returns { roots: [...], children_map: { parent_id => [children] } }
  # Builds a full recursive tree of all visible projects.
  def project_tree
    @project_tree ||= begin
      all = Project.visible(@current_user).active.order(:name)
      all_ids = all.map(&:id).to_set
      children_map = all.each_with_object(Hash.new { |h, k| h[k] = [] }) do |p, map|
        map[p.parent_id] << p
      end
      roots = all.select { |p| p.parent_id.nil? || !all_ids.include?(p.parent_id) }
      { roots: roots, children_map: children_map }
    end
  rescue StandardError
    { roots: [], children_map: Hash.new { |h, k| h[k] = [] } }
  end

  # True if project or any of its descendants is the current project.
  def project_expanded?(project, children_map)
    return false unless @current_project
    return true if @current_project.id == project.id
    (children_map[project.id] || []).any? { |child| project_expanded?(child, children_map) }
  end

  def active_item?(project)
    @current_project&.id == project.id
  end

  def project_color(project)
    PALETTE[project.id % PALETTE.length]
  end

  def project_path(project)
    "/projects/#{project.identifier}/work_packages"
  end

  def assigned_url
    "/work_packages?query_props=#{ASSIGNED_FILTER}"
  end

  def overdue_url
    "/work_packages?query_props=#{OVERDUE_FILTER}"
  end
end
