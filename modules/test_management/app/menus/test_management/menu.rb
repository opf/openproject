# frozen_string_literal: true

module TestManagement
  class Menu < Submenu
    SECTIONS = %w[cases assistant runs plans milestones ci].freeze

    PLACEHOLDER_SECTIONS = %w[ci].freeze

    CONTROLLER_SECTIONS = {
      "test_management/test_cases" => "cases",
      "test_management/suites" => "cases",
      "test_management/exports" => "cases",
      "test_management/assistant" => "assistant",
      "test_management/test_runs" => "runs",
      "test_management/test_run_cases" => "runs",
      "test_management/test_run_iterations" => "runs",
      "test_management/test_run_attachments" => "runs",
      "test_management/ci_triggers" => "runs",
      "test_management/test_plans" => "plans",
      "test_management/test_plan_entries" => "plans",
      "test_management/milestones" => "milestones"
    }.freeze

    def self.section_for(controller_path, page = nil)
      path = controller_path.to_s.delete_prefix("/")
      return page.to_s if path == "test_management/placeholders" && PLACEHOLDER_SECTIONS.include?(page.to_s)

      CONTROLLER_SECTIONS[path]
    end

    attr_reader :user

    def initialize(project:, params:, user: User.current)
      super(view_type: nil, project:, params:)
      @user = user
    end

    def current_section
      section = params[:section].to_s
      SECTIONS.include?(section) ? section : nil
    end

    def menu_items
      [menu_group(header: nil, children: section_items)]
    end

    def visible_sections
      SECTIONS.select { |section| visible?(section) }
    end

    def section_items
      visible_sections.map do |section|
        menu_item(title: I18n.t("test_management.menu.#{section}"),
                  href: section_path(section),
                  selected: section == current_section)
      end
    end

    def section_path(section)
      case section
      when "cases" then project_test_management_test_cases_path(project)
      when "assistant" then project_test_management_assistant_path(project)
      when "runs" then project_test_management_test_runs_path(project)
      when "plans" then project_test_management_test_plans_path(project)
      when "milestones" then project_test_management_milestones_path(project)
      else project_test_management_placeholder_path(project, page: section)
      end
    end

    def query_path(_query_params)
      project_test_management_test_cases_path(project)
    end

    private

    def visible?(section)
      return false unless project&.module_enabled?(:test_management)

      case section
      when "cases" then allowed?("test_management/test_cases", :index)
      when "assistant" then TestManagement::Assistant.allowed?(user, project)
      when "runs" then allowed?("test_management/test_runs", :index)
      when "plans" then TestManagement::TestPlan.enabled_for?(project) && allowed?("test_management/test_plans", :index)
      when "milestones" then TestManagement::Milestone.enabled_for?(project) && allowed?("test_management/milestones", :index)
      when "ci" then allowed?("test_management/ci_connections", :create) ||
        user.allowed_in_project?(:manage_test_ci, project)
      else false
      end
    end

    def allowed?(controller, action)
      user.allowed_in_project?({ controller:, action: }, project)
    end
  end
end
