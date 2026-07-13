# frozen_string_literal: true

module ResourcePlanners
  module Forms
    class DatesForm < ApplicationForm
      def initialize(dialog_id: ResourcePlanners::NewDialogComponent::DIALOG_ID)
        super()
        @dialog_id = dialog_id
      end

      form do |f|
        f.group(layout: :horizontal) do |dates|
          dates.single_date_picker(
            name: :start_date,
            label: ResourcePlanner.human_attribute_name(:start_date),
            required: false,
            value: model.start_date&.iso8601,
            datepicker_options: {
              inDialog: @dialog_id
            }
          )
          dates.single_date_picker(
            name: :end_date,
            label: ResourcePlanner.human_attribute_name(:end_date),
            required: false,
            value: model.end_date&.iso8601,
            datepicker_options: {
              inDialog: @dialog_id
            }
          )
        end
      end
    end
  end
end
