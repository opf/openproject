# frozen_string_literal: true

module TestManagement
  module AssistantGenerations
    # params: source_type, source { work_package_id | text | url | code, language },
    #         options { count, types, suite_id, label_names }
    class SetAttributesService < ::BaseServices::SetAttributes
      private

      def set_attributes(params)
        params = params.to_h.with_indifferent_access
        model.project = params[:project] if params.key?(:project)
        model.source_type = params[:source_type].to_s
        model.source = clean_source(model.source_type, params[:source] || {})
        model.options = clean_options(params[:options] || {})
        set_default_attributes(params) if model.new_record?
      end

      def set_default_attributes(_params)
        model.user ||= user
        model.status ||= "queued"
        model.progress_step ||= "queued"
        remember_provider
      end

      # 0021: the provider and model picked in the header when the request was sent.
      def remember_provider
        choice = TestManagement::Assistant::ProviderChoice.for(model.user)
        model.provider_id ||= choice.provider&.id
        model.chosen_model ||= choice.provider && choice.model
      end

      def clean_source(type, source)
        source = source.to_h.with_indifferent_access
        case type
        when "work_package" then { "work_package_id" => source[:work_package_id].to_s.delete_prefix("#").strip }
        when "text" then { "text" => source[:text].to_s }
        when "pull_request" then { "url" => source[:url].to_s.strip.first(2048) }
        when "code" then { "code" => source[:code].to_s, "language" => source[:language].to_s.strip.first(40) }
        else {}
        end
      end

      def clean_options(options)
        options = options.to_h.with_indifferent_access
        labels = options[:label_names]
        labels = labels.split(",") if labels.is_a?(String)
        {
          "count" => (options[:count].presence || TestManagement::AssistantGeneration::DEFAULT_COUNT).to_s.strip,
          "types" => Array(options[:types].presence || TestManagement::AssistantGeneration::DEFAULT_CASE_TYPES).map(&:to_s).compact_blank.uniq,
          "suite_id" => options[:suite_id].to_s.strip.presence,
          "label_names" => Array(labels).map { it.to_s.strip }.compact_blank.uniq
        }
      end
    end
  end
end
