# frozen_string_literal: true

module ResourcePlanners
  module Forms
    class DatesForm < ApplicationForm
      def initialize(dialog_id: ResourcePlanners::NewDialogComponent::DIALOG_ID)
        super()
        @dialog_id = dialog_id
      end

      form do |f|
        f.range_date_picker(
          name: :date_range,
          label: ResourcePlanner.human_attribute_name(:date_range),
          required: false,
          value: model.date_range,
          validation_message: date_validation_message,
          input_width: :large,
          datepicker_options: {
            inDialog: @dialog_id,
            showClearButton: true
          }
        )
      end

      private

      # The picker is a single input, so the errors both dates can carry have to
      # be surfaced on it together.
      def date_validation_message
        (model.errors.full_messages_for(:start_date) + model.errors.full_messages_for(:end_date))
          .to_sentence
          .presence
      end
    end
  end
end
