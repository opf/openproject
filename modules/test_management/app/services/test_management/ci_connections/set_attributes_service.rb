# frozen_string_literal: true

module TestManagement
  module CiConnections
    # Blank secrets keep the stored ones (the forms never contain them); "remove_token" /
    # "remove_trigger_token" clear them. A blank scm_repository_id detaches the repository.
    class SetAttributesService < ::BaseServices::SetAttributes
      SECRETS = %w[token trigger_token].freeze

      private

      def set_attributes(params)
        params = params.to_h.with_indifferent_access
        SECRETS.each { |key| params.delete(key) if params.key?(key) && params[key].blank? }
        params[:scm_repository_id] = params[:scm_repository_id].presence if params.key?(:scm_repository_id)

        super
      end

      def set_default_attributes(_params)
        model.created_by ||= user
      end
    end
  end
end
