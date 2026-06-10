# frozen_string_literal: true

module ResourcePlanners
  module Forms
    class DatesForm < ApplicationForm
      form do |f|
        f.group(layout: :horizontal) do |dates|
          dates.single_date_picker(
            name: :start_date,
            label: ResourcePlanner.human_attribute_name(:start_date),
            required: false,
            value: model.start_date&.iso8601,
            datepicker_options: {
              inDialog: ResourcePlanners::NewDialogComponent::DIALOG_ID
            }
          )
          dates.single_date_picker(
            name: :end_date,
            label: ResourcePlanner.human_attribute_name(:end_date),
            required: false,
            value: model.end_date&.iso8601,
            datepicker_options: {
              inDialog: ResourcePlanners::NewDialogComponent::DIALOG_ID
            }
          )
        end
      end
    end
  end
end
