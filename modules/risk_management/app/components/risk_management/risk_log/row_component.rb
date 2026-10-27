# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class RowComponent < OpPrimer::BorderBoxRowComponent
      alias_method :work_package, :model

      def subject
        render(
          Primer::Beta::Link.new(
            href: helpers.project_risk_log_details_path(
              table.project,
              work_package,
              table.query_params.except(:split_view)
            ),
            font_weight: :bold,
            underline: false,
            data: { turbo_frame: "content-bodyRight", turbo_action: "advance" }
          )
        ) { work_package.subject }
      end

      def status
        render(WorkPackages::StatusBadgeComponent.new(status: work_package.status))
      end

      def likelihood
        value = work_package.risk_likelihood
        value.present? ? helpers.number_to_percentage(value, precision: 2, strip_insignificant_zeros: true) : placeholder
      end

      def impact
        value = work_package.risk_impact
        value.present? ? helpers.number_to_currency(value, precision: 0) : placeholder
      end

      def risk_value
        value = assessment.risk_value
        value ? helpers.number_to_currency(value, precision: 0) : placeholder
      end

      def category
        return placeholder if category_values.empty?

        helpers.safe_join(category_values.each_with_index.map { |value, index| category_label(value, index) }, " ")
      end

      def owner
        work_package.risk_owner&.name || placeholder
      end

      def button_links
        [action_menu]
      end

      private

      def action_menu
        render(Primer::Alpha::ActionMenu.new) do |menu|
          menu.with_show_button(
            icon: "kebab-horizontal",
            "aria-label": I18n.t(:label_more),
            scheme: :invisible,
            test_selector: "risk-row-more-#{work_package.id}"
          )

          open_details_item(menu)
          open_work_package_item(menu)
          add_to_agenda_item(menu) if add_to_agenda_available?
        end
      end

      def open_details_item(menu)
        menu.with_item(
          label: I18n.t("risk_management.risk_log.actions.open_details"),
          href: helpers.project_risk_log_details_path(
            table.project,
            work_package,
            table.query_params.except(:split_view)
          ),
          content_arguments: { data: { turbo_frame: "content-bodyRight", turbo_action: "advance" } }
        ) { |item| item.with_leading_visual_icon(icon: :"op-view-split") }
      end

      def open_work_package_item(menu)
        menu.with_item(
          label: I18n.t("risk_management.risk_log.actions.open_work_package"),
          href: helpers.project_work_package_path(table.project, work_package),
          content_arguments: { data: { turbo_frame: "_top" } }
        ) { |item| item.with_leading_visual_icon(icon: :"screen-full") }
      end

      def add_to_agenda_item(menu)
        menu.with_item(
          label: I18n.t("risk_management.risk_log.actions.add_to_agenda"),
          href: helpers.dialog_project_work_package_meeting_agenda_items_path(table.project, work_package),
          content_arguments: { data: { controller: "async-dialog" } }
        ) { |item| item.with_leading_visual_icon(icon: :calendar) }
      end

      def add_to_agenda_available?
        helpers.respond_to?(:dialog_project_work_package_meeting_agenda_items_path) &&
          table.project.module_enabled?(:meetings) &&
          User.current.allowed_in_any_project?(:manage_agendas)
      end

      def category_schemes
        %i[accent success attention severe danger secondary]
      end

      def category_values
        @category_values ||= work_package.risk_category_ids.filter_map { |id| table.categories[id]&.name }
      end

      def category_label(value, index)
        scheme = category_schemes[index % category_schemes.length]
        render(Primer::Beta::Label.new(scheme:)) { value }
      end

      def assessment
        @assessment ||= Assessment.new(
          likelihood: work_package.risk_likelihood,
          impact: work_package.risk_impact,
          configuration: table.configuration
        )
      end

      def placeholder
        render(Primer::Beta::Text.new(color: :muted)) { "–" }
      end
    end
  end
end
