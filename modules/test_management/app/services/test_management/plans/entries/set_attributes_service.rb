# frozen_string_literal: true

module TestManagement
  module Plans
    module Entries
      class SetAttributesService < ::BaseServices::SetAttributes
        private

        def set_attributes(params)
          params = params.to_h.with_indifferent_access
          filter = params.key?(:filter_options) ? params.delete(:filter_options) : nil
          case_ids = params.key?(:case_ids) ? params.delete(:case_ids) : nil
          case_ids = params.delete(:test_case_ids) if case_ids.nil? && params.key?(:test_case_ids)
          config_ids = params.key?(:configuration_ids) ? params.delete(:configuration_ids) : nil
          params[:assigned_to_id] = params[:assigned_to_id].presence if params.key?(:assigned_to_id)

          super

          model.filter_options = normalize_filter(filter) unless filter.nil?
          model.case_ids = ids_from(case_ids) unless case_ids.nil?
          model.configuration_ids = ids_from(config_ids) unless config_ids.nil?
        end

        def set_default_attributes(_params)
          model.selection_mode ||= "specific"
          model.position ||= model.test_plan ? model.test_plan.entries.maximum(:position).to_i + 1 : 0
          model.filter_options ||= {}
          model.case_ids ||= []
          model.configuration_ids ||= []
        end

        def normalize_filter(raw)
          raw = raw.to_h.with_indifferent_access
          automation = raw[:automation].to_s
          {
            "label_ids" => ids_from(raw[:label_ids]),
            "suite_ids" => ids_from(raw[:suite_ids]),
            "automation" => TestRun::AUTOMATION_FILTERS.include?(automation) ? automation : "any"
          }
        end

        def ids_from(raw)
          Array(raw)
            .flat_map { |value| value.to_s.split(/[\s,]+/) }
            .map { |value| value.delete_prefix("#") }
            .grep(/\A\d+\z/)
            .map(&:to_i)
            .uniq
        end
      end
    end
  end
end
