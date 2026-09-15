# frozen_string_literal: true

module HourlyRates
  class RateFormComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    FORM_ID = "hourly-rate-form"

    options :rate, :form_url

    private

    def form_method
      rate.persisted? ? :patch : :post
    end

    def submit_label
      rate.persisted? ? t(:button_save) : t(:button_create)
    end

    def base_errors
      rate.errors.full_messages_for(:base)
    end
  end
end
