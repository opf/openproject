# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  module DatePicker
    class DateFormComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      FOCUSED_CLASS = "op-datepicker-modal--date-field_current"

      attr_reader :work_package

      def initialize(work_package:,
                     schedule_manually:,
                     disabled:,
                     is_milestone:,
                     focused_field: :start_date,
                     triggering_field: nil,
                     touched_field_map: nil,
                     date_mode: nil)
        super()

        @work_package = work_package
        @schedule_manually = schedule_manually
        @is_milestone = is_milestone
        @date_mode = date_mode
        @touched_field_map = touched_field_map
        @triggering_field = triggering_field
        @focused_field = update_focused_field(focused_field)
        @disabled = disabled
      end

      private

      def container_classes(name)
        classes = "wp-datepicker-dialog-date-form--button-container"
        classes += " wp-datepicker-dialog-date-form--button-container_visible" unless show_text_field?(name)

        classes
      end

      def show_text_field?(name)
        return true if @is_milestone || !@schedule_manually
        return true if range_date_mode?

        show_text_field_in_single_date_mode?(name)
      end

      def text_field_options(name:, label:)
        text_field_options = default_field_options(name).merge(
          name: "work_package[#{name}]",
          id: "work_package_#{name}",
          value: field_value(name),
          disabled: disabled?(name),
          label:,
          show_clear_button: show_clear_button?(name),
          classes: "op-datepicker-modal--date-field #{FOCUSED_CLASS if focused?(name)}",
          validation_message: validation_message(name),
          type: field_type(name),
          readonly: readonly?
        )

        if duration_field?(name)
          text_field_options = text_field_options.merge(
            trailing_visual: { text: { text: I18n.t("datetime.units.day.other") } }
          )
        end

        text_field_options
      end

      def render_today_link(name:)
        return if duration_field?(name)

        text = I18n.t(:label_today).capitalize

        return text if @disabled

        render(
          Primer::Beta::Link.new(
            href: "",
            "aria-label": @is_milestone ? I18n.t("label_today_as_date") : I18n.t("label_today_as_#{name}"),
            data: {
              action: "work-packages--date-picker--preview#setTodayForField",
              "work-packages--date-picker--preview-field-reference-param": "work_package_#{name}",
              test_selector: "op-datepicker-modal--#{name.to_s.dasherize}-field--today"
            }
          )
        ) { text }
      end

      def duration_field?(name)
        name == :duration
      end

      def show_duration?
        # On mobile, we want to hide the duration field to gain some space
        !!helpers.browser.device.mobile?
      end

      def start_date_label
        if @is_milestone
          I18n.t("attributes.date")
        else
          I18n.t("attributes.start_date")
        end
      end

      def update_focused_field(focused_field)
        if @date_mode.nil? || @date_mode != "range"
          return focused_field_for_single_date_mode(focused_field)
        end

        date_fields = {
          "due_date" => :due_date,
          "start_date" => :start_date,
          "duration" => :duration
        }

        # Default is :start_date
        date_fields.fetch(focused_field.to_s.underscore, :start_date)
      end

      def focused_field_for_single_date_mode(focused_field)
        return :duration if focused_field.to_s == "duration"

        # When the combined date is triggered, we have to actually check for the values.
        # This happens only on initialization
        if focused_field == :combined_date
          return :due_date if field_value(:start_date).nil?
          return :start_date if field_value(:due_date).nil?
        end

        # Focus the field if it is shown..
        return focused_field if show_text_field?(focused_field)

        # .. if not, focus the other one
        focused_field == :start_date ? :due_date : :start_date
      end

      def disabled?(name)
        if name == :start_date && !@schedule_manually
          return true
        end

        @disabled
      end

      def focused?(name)
        @focused_field == name && !disabled?(name)
      end

      def field_value(name)
        errors = @work_package.errors.where(name)
        if (user_value = errors.map { |error| error.options[:value] }.find { !it.nil? })
          user_value
        else
          @work_package.public_send(name)
        end
      end

      def field_type(name)
        duration_field?(name) ? :number : :text
      end

      def validation_message(name)
        # it's ok to take the first error only, that's how primer_view_component does it anyway.
        message = @work_package.errors.messages_for(name).first
        message&.upcase_first
      end

      def default_field_options(name)
        data = { "work-packages--date-picker--preview-target": "fieldInput",
                 action: "work-packages--date-picker--preview#markFieldAsTouched " \
                         "work-packages--date-picker--preview#inputChanged " \
                         "focus->work-packages--date-picker--preview#onHighlightField",
                 test_selector: "op-datepicker-modal--#{name.to_s.dasherize}-field" }

        if focused?(name)
          data[:qa_highlighted] = "true"
          data[:focus] = "true"
        end

        { data: data }
      end

      def single_date_field_button_link(focused_field)
        permitted_params = params.merge(date_mode: "range", focused_field:).permit!

        if work_package.new_record?
          preview_date_picker_path(permitted_params)
        else
          preview_work_package_date_picker_path(work_package, permitted_params)
        end
      end

      def range_date_mode?
        @date_mode.present? && @date_mode == "range"
      end

      def field_value_present_or_touched?(name)
        field_value(name).present? || @touched_field_map["#{name}_touched"]
      end

      def show_text_field_in_single_date_mode?(name)
        return true if field_value_present_or_touched?(name)

        # Special case, if the use explicitly clicks on start date, we want to show that field
        if table_triggered_date_field?
          return normalized_underscore_name(name) == normalized_underscore_name(@triggering_field)
        end

        # Start date is only shown in the assertion above
        return false if name != :due_date

        # This handles the edge case, that the datepicker starts in single date mode, with the due date being hidden.
        # Normally, the start date is the hidden one, except if only a start date is set.
        # In case we delete the start date, we have to ensure that the datepicker does not switch the fields
        # and suddenly hides the start date. That is why we check for the touched value.
        true if field_value(:start_date).nil? &&
          (@touched_field_map["start_date_touched"] == false || @touched_field_map["start_date_touched"].nil?)
      end

      def table_triggered_date_field?
        ["start_date", "due_date"].include?(normalized_underscore_name(@triggering_field))
      end

      def normalized_underscore_name(name)
        name.to_s.underscore
      end

      def show_clear_button?(name)
        !disabled?(name) && !duration_field?(name)
      end

      def readonly?
        # On mobile, the fields are readonly because of iOS Safari
        # Do not show the native datepicker on iOS safari because it
        # behaves totally different than all other browsers and destroys the behavior of the datepicker
        # Given a date field with no value: When Safari opens its native datepicker, the first thing it does is to
        # set the date to Today. And not only in the datepicker but directly in the field.
        # This behaviour has however consequences:
        # * The "reset" button in the datepicker does not clear the input (as the other browsers do it) but it resets
        #   it to the original value it had when you opened it. So if the value was empty, it sets it back to empty.
        #   If the value was set before, you cannot clear it, but only set it back to that value.
        # * Since the input changes, the whole datepicker updates without the user even knowing about it,
        #   since the form is hidden behind the datepicker. That leads to this:
        #     - when you enter a start date after today, and then open the datepicker for finish date,
        #       it will reset the start date because the finish date is set automatically to today,
        #       but the finish date can't be before the start date.
        helpers.browser.device.mobile?
      end
    end
  end
end
