# frozen_string_literal: true

module Storages
  module Admin
    module Sidebar
      class HealthStatusComponent < ApplicationComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
        include ApplicationHelper
        include OpTurbo::Streamable
        include OpPrimer::ComponentHelpers

        def initialize(storage:)
          super(storage)
          @storage = storage
        end

        private

        def health_status_indicator
          case @storage.health_status
          when "healthy"
            { scheme: :success, label: I18n.t("storages.health.label_healthy") }
          when "unhealthy"
            { scheme: :danger, label: I18n.t("storages.health.label_error") }
          else
            { scheme: :attention, label: I18n.t("storages.health.label_pending") }
          end
        end

        # This method returns the health identifier, description and the time since when the error occurs in a
        # formatted manner. e.g. "Not found: Outbound request destination not found since 12/07/2023 03:45 PM"
        def formatted_health_reason
          "#{@storage.health_reason_identifier.tr('_', ' ').strip.capitalize}: #{@storage.health_reason_description} " +
            I18n.t("storages.health.since", datetime: helpers.format_time(@storage.health_changed_at))
        end

        def validation_result_placeholder
          ConnectionValidation.new(type: :none,
                                   timestamp: Time.current,
                                   description: I18n.t("storages.health.connection_validation.placeholder"))
        end
      end
    end
  end
end
