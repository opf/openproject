# frozen_string_literal: true

module TestManagement
  module AssistantMessages
    class SetAttributesService < ::BaseServices::SetAttributes
      private

      def set_attributes(params)
        params = params.to_h.with_indifferent_access
        model.project = params[:project] if params.key?(:project)
        model.content = params[:content].to_s.strip
        set_default_attributes(params) if model.new_record?
      end

      def set_default_attributes(_params)
        model.user ||= user
        model.role ||= "user"
        model.state ||= "done"
        # 0021: the provider and model picked in the header when the question was sent.
        choice = TestManagement::Assistant::ProviderChoice.for(model.user)
        model.provider_id ||= choice.provider&.id
        model.chosen_model ||= choice.provider && choice.model
      end
    end
  end
end
