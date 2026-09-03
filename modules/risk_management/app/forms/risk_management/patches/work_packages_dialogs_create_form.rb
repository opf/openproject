# frozen_string_literal: true

module RiskManagement
  module Patches
    module WorkPackagesDialogsCreateForm
      private

      def render_type_selector(form:)
        return super unless risk_work_package?

        form.hidden(name: :type_id, value: work_package.type_id)
      end

      def subject_input_width
        risk_work_package? ? :full : super
      end

      def render_additional_attributes(form:)
        super
        return unless risk_work_package?

        render_assignee(form)
        render_risk_owner(form)
        render_risk_assessment(form)
        render_risk_categories(form)
        render_risk_response(form)
      end

      def render_assignee(form)
        render_principal_field(
          form:,
          name: :assigned_to_id,
          label: WorkPackage.human_attribute_name(:assigned_to),
          principals: contract.assignable_assignees,
          selected_id: work_package.assigned_to_id
        )
      end

      def render_risk_owner(form)
        render_principal_field(
          form:,
          name: :risk_owner_id,
          label: WorkPackage.human_attribute_name(:risk_owner),
          principals: contract.assignable_risk_owners,
          selected_id: work_package.risk_owner_id
        )
      end

      def render_risk_assessment(form)
        form.group(layout: :horizontal) do |row|
          row.text_field(
            name: :risk_likelihood,
            label: WorkPackage.human_attribute_name(:risk_likelihood),
            type: "number",
            min: 0,
            max: 100,
            step: 0.01,
            trailing_visual: { text: { text: "%" } }
          )
          row.text_field(
            name: :risk_impact,
            label: WorkPackage.human_attribute_name(:risk_impact),
            type: "number",
            min: 0,
            step: 1,
            trailing_visual: { text: { text: Setting.costs_currency } }
          )
        end
      end

      def render_risk_categories(form)
        form.autocompleter(
          name: :risk_category_ids,
          label: WorkPackage.human_attribute_name(:risk_category_ids),
          include_blank: true,
          input_width: :large,
          autocomplete_options: {
            multiple: true,
            decorated: true,
            clearable: true,
            focusDirectly: false,
            append_to: wrapper_id
          }
        ) do |select|
          RiskManagement::RiskCategory.active.order(:position).each do |category|
            select.option(
              label: category.name,
              value: category.id,
              selected: work_package.risk_category_ids.include?(category.id)
            )
          end
        end
      end

      def render_risk_response(form)
        form.select_list(
          name: :risk_response,
          label: WorkPackage.human_attribute_name(:risk_response),
          include_blank: true,
          input_width: :medium
        ) do |select|
          %w[mitigate accept avoid transfer].each do |response|
            select.option(
              label: I18n.t("risk_management.risk_responses.#{response}"),
              value: response,
              selected: work_package.risk_response == response
            )
          end
        end
      end

      def render_principal_field(form:, name:, label:, principals:, selected_id:)
        form.autocompleter(
          name:,
          label:,
          include_blank: true,
          input_width: :large,
          autocomplete_options: {
            multiple: false,
            decorated: true,
            clearable: true,
            focusDirectly: false,
            append_to: wrapper_id
          }
        ) do |select|
          principals.order(:lastname, :firstname).each do |principal|
            select.option(label: principal.name, value: principal.id, selected: selected_id == principal.id)
          end
        end
      end

      def risk_work_package?
        risk_configuration.valid? && work_package.type_id == risk_configuration.risk_type_id
      end

      def risk_configuration
        @risk_configuration ||= ::RiskManagement::Configuration.load
      end
    end
  end
end
