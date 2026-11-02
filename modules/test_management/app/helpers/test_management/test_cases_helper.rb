# frozen_string_literal: true

module TestManagement
  module TestCasesHelper
    def tm_suite_count(suite, suite_counts:, suites: nil)
      direct = suite_counts&.[](suite.id).to_i
      children = suites&.select { |s| s.parent_id == suite.id } || suite.children
      direct + children.sum { |child| tm_suite_count(child, suite_counts:, suites:) }
    end

    def tm_folder_tree_link(project:, suite_id:, label:, count:, selected:, icon: nil)
      link_to project_test_management_test_cases_path(project, suite_id:),
              class: ["tm-folder-item", ("is-selected" if selected)].compact.join(" "),
              "aria-current": (selected ? "page" : nil),
              data: { test_selector: "tm-folder-#{suite_id || 'all'}" } do
        if icon
          concat render(Primer::Beta::Octicon.new(icon:, size: :small, classes: "tm-folder-item--icon",
                                                  "aria-hidden": true))
        end
        concat content_tag(:span, label, class: "tm-folder-item--label")
        concat render(Primer::Beta::Counter.new(count: count.to_i,
                                                scheme: :secondary,
                                                hide_if_zero: false,
                                                classes: "tm-folder-item--count"))
      end
    end

    # Renders folders as a nested tree. Branches use <details>/<summary> so they
    # expand/collapse natively (no JS, CSP-safe). Clicking the folder name
    # navigates (links inside <summary> don't toggle); the chevron toggles.
    # All branches start expanded.
    def tm_render_suite_nodes(project:, suites:, suite_counts:, parent_id: nil, depth: 0, current_suite_id: nil)
      by_parent = suites.group_by(&:parent_id)
      tm_render_suite_level(project, by_parent, parent_id, depth, current_suite_id.to_s, suite_counts:, suites:)
    end

    def tm_render_suite_level(project, by_parent, parent_id, depth, current_suite_id, suite_counts:, suites:)
      Array(by_parent[parent_id]).map do |suite|
        link = tm_folder_tree_link(
          project:,
          suite_id: suite.id,
          label: suite.name,
          count: tm_suite_count(suite, suite_counts:, suites:),
          selected: current_suite_id == suite.id.to_s,
          icon: :"file-directory"
        )
        children = tm_render_suite_level(project, by_parent, suite.id, depth + 1, current_suite_id,
                                         suite_counts:, suites:)

        content_tag(:li, class: "tm-folder-node depth-#{depth}", data: { test_selector: "tm-folder-node-#{suite.id}" }) do
          if children.any?
            content_tag(:details, class: "tm-folder-branch", open: true) do
              content_tag(:summary, class: "tm-folder-row") do
                content_tag(:span, class: "tm-folder-chevron", title: t("test_management.suites.toggle")) do
                  render(Primer::Beta::Octicon.new(icon: :"chevron-right", size: :small, "aria-hidden": true))
                end + link
              end + content_tag(:ul, safe_join(children), class: "tm-folder-children")
            end
          else
            content_tag(:div, class: "tm-folder-row") do
              content_tag(:span, "", class: "tm-folder-chevron tm-folder-chevron--leaf") + link
            end
          end
        end
      end
    end

    def tm_priority_label(priority)
      content_tag(:span, priority.to_s, class: "tm-priority tm-priority-#{priority}")
    end

    def tm_status_label(status)
      content_tag(:span, class: "tm-status tm-status-#{status}") do
        concat content_tag(:span, "", class: "tm-status-dot", "aria-hidden": true)
        concat " #{status}"
      end
    end

    # Work packages linked to the case that the current user may see, for display.
    def tm_visible_linked_work_packages(test_case, user = User.current)
      return ::WorkPackage.none if test_case.new_record?

      test_case.work_packages
               .visible(user)
               .includes(:type, :status)
               .order(:id)
    end

    # Preselected chips for the work package autocompleter. Passed as a ready-made
    # `model` (not `inputValue`) so the hidden work_package_ids[] inputs exist as soon
    # as the component renders, without waiting for per-ID API calls. Only visible
    # work packages are included.
    def tm_work_package_autocompleter_model(test_case, user = User.current)
      ids = test_case.linked_work_package_ids
      return [] if ids.empty?

      ::WorkPackage.visible(user)
                   .where(id: ids)
                   .includes(:type)
                   .order(:id)
                   .map do |wp|
        {
          id: wp.id,
          subject: wp.subject,
          name: wp.subject,
          formattedId: tm_work_package_reference(wp),
          type: { name: wp.type&.name }
        }
      end
    end

    def tm_work_package_reference(work_package)
      if work_package.respond_to?(:formatted_id)
        work_package.formatted_id
      else
        "##{work_package.id}"
      end
    end

    DEFECT_TYPE_NAMES = %w[bug defect].freeze

    # Linked work packages counted as defects (Defects tab). PoC rule: the type
    # name is "Bug" or "Defect" (case-insensitive).
    def tm_defect_work_package?(work_package)
      DEFECT_TYPE_NAMES.include?(work_package.type&.name.to_s.strip.downcase)
    end

    def tm_unknown
      content_tag(:span, "—", class: "color-fg-muted")
    end

    # "<user link> on <formatted time>", or "—" when the user is unknown.
    def tm_user_and_time(user, time)
      return tm_unknown if user.nil?

      parts = [link_to_user(user)]
      parts << t("test_management.cases.on_time", time: format_time(time)) if time
      safe_join(parts, " ")
    end

    # Human-readable lines for a TestCaseEvent's details.
    def tm_history_lines(event)
      details = event.details || {}
      details.filter_map do |key, value|
        # Only humanize real attributes (lazily): OpenProject raises on missing
        # translations in tests, and keys like "steps" or "run_id" have none.
        label = -> { TestManagement::TestCase.human_attribute_name(key == "suite_id" ? "suite" : key) }
        case key
        when "steps"
          t("test_management.history.steps_changed")
        when "labels"
          added = Array(value["added"])
          removed = Array(value["removed"])
          parts = []
          parts << t("test_management.history.wp_added", ids: added.join(", ")) if added.any?
          parts << t("test_management.history.wp_removed", ids: removed.join(", ")) if removed.any?
          "#{TestManagement::TestCase.human_attribute_name(:labels)}: #{parts.join('; ')}"
        when "run_id", "run_name", "import_id", "source", "commit_sha"
          nil
        when "status"
          if event.action == "automation_result"
            t("test_management.history.automation_result_line",
              run: "R#{details['run_id']} \u201C#{details['run_name']}\u201D",
              status: t("test_management.runs.statuses.#{value}"))
          elsif event.action.start_with?("run_")
            t("test_management.history.run_finished_line",
              run: "R#{details['run_id']} \u201C#{details['run_name']}\u201D",
              state: t("test_management.runs.states.#{event.action.delete_prefix('run_')}").downcase,
              status: t("test_management.runs.statuses.#{value}"))
          else
            old_value, new_value = Array(value)
            t("test_management.history.value_changed", attribute: label.call,
                                                       from: tm_history_value(key, old_value),
                                                       to: tm_history_value(key, new_value))
          end
        when "work_packages"
          added = Array(value["added"]).map { |id| "##{id}" }
          removed = Array(value["removed"]).map { |id| "##{id}" }
          parts = []
          parts << t("test_management.history.wp_added", ids: added.join(", ")) if added.any?
          parts << t("test_management.history.wp_removed", ids: removed.join(", ")) if removed.any?
          "#{t('test_management.cases.linked_work_packages')}: #{parts.join('; ')}"
        else
          if value == true
            t("test_management.history.text_changed", attribute: label.call)
          else
            old_value, new_value = Array(value)
            t("test_management.history.value_changed",
              attribute: label.call,
              from: tm_history_value(key, old_value),
              to: tm_history_value(key, new_value))
          end
        end
      end
    end

    def tm_history_value(key, value)
      return "—" if value.nil? || value == ""
      return (value ? t(:general_text_Yes) : t(:general_text_No)) if key == "automated"

      value.to_s
    end

    # --- Labels ---------------------------------------------------------------
    def tm_label(label)
      render(Primer::Beta::Label.new(scheme: label.color.to_sym, size: :medium,
                                     classes: "tm-label",
                                     data: { test_selector: "tm-label" })) { label.name }
    end

    def tm_labels(labels)
      list = Array(labels).sort_by { |label| label.name.downcase }
      return "".html_safe if list.empty?

      content_tag(:span, safe_join(list.map { |label| tm_label(label) }, " "), class: "tm-labels")
    end

    def tm_project_labels(project)
      TestManagement::Label.where(project_id: project.id).ordered.to_a
    end
  end
end
