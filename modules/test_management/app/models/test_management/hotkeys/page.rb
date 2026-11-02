# frozen_string_literal: true

module TestManagement
  module Hotkeys
    # Shortcuts, "up" target, hints and the random tip for one request (0019). Built by the layout
    # hook from the hook context (project, controller); returns nothing outside projects with the
    # module, when an admin switched the shortcuts off, or when the user disabled keyboard shortcuts
    # (core "Disable keyboard shortcuts" preference, which also turns core shortcuts off).
    class Page
      include Rails.application.routes.url_helpers

      # "n t c" on the Cases list focuses the quick-create title instead of opening the form.
      FOCUS_TARGETS = { "new_case" => "#tm-new-case-title" }.freeze

      attr_reader :project, :user, :controller_path, :action_name

      def self.from_context(context, user: User.current)
        controller = context[:controller]
        new(project: context[:project],
            user:,
            controller_path: controller.respond_to?(:controller_path) ? controller.controller_path : nil,
            action_name: controller.respond_to?(:action_name) ? controller.action_name : nil,
            params: controller.respond_to?(:params) ? controller.params : {},
            assigns: controller ? ->(name) { controller.instance_variable_get(:"@#{name}") } : ->(_) {})
      end

      def initialize(project:, user:, controller_path: nil, action_name: nil, params: {}, assigns: ->(_) {})
        @project = project
        @user = user
        @controller_path = controller_path.to_s.delete_prefix("/")
        @action_name = action_name.to_s
        @params = params
        @assigns = assigns
      end

      def default_url_options
        { script_name: OpenProject::Configuration.rails_relative_url_root }
      end

      def active?
        project.is_a?(::Project) && project.persisted? &&
          project.module_enabled?(:test_management) &&
          Hotkeys.enabled? &&
          !keyboard_shortcuts_disabled? &&
          shortcuts.any?
      end

      def keyboard_shortcuts_disabled?
        user.pref.disable_keyboard_shortcuts?
      rescue StandardError
        false
      end

      # A Test management page (controllers of the module except the project and admin settings).
      def module_page?
        controller_path.start_with?("test_management/") &&
          !controller_path.start_with?("test_management/admin") &&
          controller_path != "test_management/project_settings"
      end

      # [{ id:, keys:, href: }] the user can use on this page, in mapping order.
      def shortcuts
        @shortcuts ||= begin
          list = Hotkeys::SHORTCUTS.filter_map do |shortcut|
            next if shortcut.module_only? && !module_page?

            href = href_for(shortcut.id)
            next if href.nil? && shortcut.id != "help"

            { id: shortcut.id, keys: shortcut.keys, href: }
          end
          list.size > 1 ? list : []
        end
      end

      def shortcut(id)
        shortcuts.find { |entry| entry[:id] == id.to_s }
      end

      def keys_for(id)
        shortcut(id)&.dig(:keys)
      end

      # Badges (<kbd>) on buttons and submenu entries.
      def hints?
        active? && Hotkeys.hints_enabled? && preferences.hotkey_hints_enabled?
      end

      # Random tips: Test management pages only, logged-in users (the "Don't show again" choice is
      # stored per user), admin switch and user preference.
      def tips?
        active? && module_page? && user.logged? && Hotkeys.hints_enabled? && preferences.hotkey_tips_enabled?
      end

      # One random tip among the shortcuts the user can use (the browser decides whether to show it).
      def tip(random: Random)
        candidates = shortcuts.reject { |entry| entry[:id] == "help" }
        candidates.empty? ? nil : candidates[random.rand(candidates.size)]
      end

      def preferences
        @preferences ||= TestManagement::UserPreference.for(user)
      end

      def config
        {
          shortcuts: shortcuts.map do |entry|
            entry.slice(:id, :keys, :href).merge(sequence: entry[:keys].split, focus: FOCUS_TARGETS[entry[:id]]).compact
          end,
          timeout: Hotkeys::SEQUENCE_TIMEOUT_MS,
          hints: hints?
        }
      end

      def href_for(id)
        case id.to_s
        when "cases" then cases_path if allowed?("test_management/test_cases", :index)
        when "runs" then runs_path if allowed?("test_management/test_runs", :index)
        when "assistant" then assistant_path if TestManagement::Assistant.allowed?(user, project)
        when "new_case" then new_case_path if allowed?("test_management/test_cases", :new)
        when "new_run" then new_project_test_management_test_run_path(project) if allowed?("test_management/test_runs", :new)
        when "up" then up_path
        end
      end

      # "Back" = one level up in the module's hierarchy, nil on top-level pages.
      def up_path
        return unless module_page?

        case controller_path
        when "test_management/test_cases" then test_case_up_path
        when "test_management/test_runs" then test_run_up_path
        when "test_management/milestones" then milestone_up_path
        when "test_management/ci_triggers" then ci_trigger_up_path
        end
      end

      private

      attr_reader :params

      def assign(name)
        @assigns.call(name)
      end

      def allowed?(controller, action)
        user.allowed_in_project?({ controller:, action: }, project)
      end

      def cases_path(suite_id = nil)
        project_test_management_test_cases_path(project, { suite_id: }.compact)
      end

      def runs_path
        project_test_management_test_runs_path(project)
      end

      def assistant_path
        project_test_management_assistant_path(project)
      end

      # On a cases page the new case lands in the folder being looked at.
      def new_case_path
        suite_id = (assign(:current_suite)&.id if controller_path == "test_management/test_cases")
        new_project_test_management_test_case_path(project, { suite_id: }.compact)
      end

      def test_case_up_path
        test_case = assign(:test_case)
        case action_name
        when "index" then folder_up_path
        when "show" then cases_path(test_case&.suite_id)
        when "edit", "update"
          test_case&.persisted? ? project_test_management_test_case_path(project, test_case) : cases_path
        when "new", "create" then cases_path(test_case&.suite_id || params[:suite_id].presence)
        end
      end

      def folder_up_path
        suite = assign(:current_suite)
        if suite
          cases_path(suite.parent_id)
        elsif params[:suite_id].present?
          cases_path # "Unfiled" and unknown folders: back to all cases
        end
      end

      def test_run_up_path
        run = assign(:test_run)
        case action_name
        when "show", "new", "create" then runs_path
        when "edit", "update"
          run&.persisted? ? project_test_management_test_run_path(project, run) : runs_path
        end
      end

      def milestone_up_path
        milestone = assign(:milestone)
        index = project_test_management_milestones_path(project)
        case action_name
        when "show"
          milestone&.parent_id ? project_test_management_milestone_path(project, milestone.parent_id) : index
        when "edit", "update"
          milestone&.persisted? ? project_test_management_milestone_path(project, milestone) : index
        when "new", "create"
          parent_id = milestone&.parent_id
          parent_id ? project_test_management_milestone_path(project, parent_id) : index
        end
      end

      def ci_trigger_up_path
        if (run = assign(:scope_run))
          project_test_management_test_run_path(project, run)
        elsif (test_case = assign(:test_case))
          project_test_management_test_case_path(project, test_case)
        elsif (suite = assign(:suite))
          cases_path(suite.id)
        else
          cases_path
        end
      end
    end
  end
end
