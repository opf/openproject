# frozen_string_literal: true

module HourlyRates
  class RateDialogComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    DIALOG_ID = "hourly-rate-dialog"

    options :rate, :form_url

    private

    def title
      rate.persisted? ? t(:button_edit) : t(:button_add_rate)
    end
  end
end
