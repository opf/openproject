# frozen_string_literal: true

module HourlyRates
  class RateForm < ApplicationForm
    form do |f|
      f.hidden(name: :user_id)

      f.single_date_picker(
        name: :valid_from,
        type: "date",
        label: Rate.human_attribute_name(:valid_from),
        required: true,
        input_width: :small,
        leading_visual: { icon: :calendar },
        datepicker_options: { inDialog: HourlyRates::RateDialogComponent::DIALOG_ID }
      )

      f.text_field(
        name: :rate,
        label: Rate.model_name.human,
        required: true,
        input_width: :small,
        autocomplete: "off",
        trailing_visual: { text: { text: Setting.costs_currency } }
      )
    end
  end
end
