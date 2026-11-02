# frozen_string_literal: true

module TestManagement
  module TestPlansHelper
    def tm_plan_can_manage?(project)
      User.current.allowed_in_project?(:manage_test_plans, project)
    end

    def tm_plan_status_label(plan)
      scheme = plan.completed? ? :success : :accent
      render(Primer::Beta::Label.new(scheme:)) { t("test_management.plans.states.#{plan.state}") }
    end

    def tm_configurations_empty_hint(project)
      return if project.tm_configuration_groups.joins(:configurations).exists?

      settings_path = project_test_management_project_settings_path(project, anchor: "tm-configurations")
      content_tag(
        :p,
        t("test_management.configurations.create_hint_html",
          link: link_to(t("test_management.configurations.settings_link"), settings_path)),
        class: "flash flash-info",
        data: { test_selector: "tm-configurations-hint" }
      )
    end
  end
end
