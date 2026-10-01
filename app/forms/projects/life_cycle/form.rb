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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
module Projects::LifeCycle
  class Form < ApplicationForm
    include BrowserAware

    form do |f|
      f.group(layout: :horizontal) do |horizontal_form|
        start_date_input(horizontal_form)
        finish_date_input(horizontal_form)
        duration_input(horizontal_form)
      end
    end

    private

    def test_selector
      "life-cycle-step-#{model.id}"
    end

    def datepicker_attributes(field_name)
      {
        name: field_name,
        label: attribute_name(field_name),
        type: field_type,
        value: value(field_name),
        autofocus: autofocus?(field_name),
        placeholder:,
        show_clear_button: show_clear_button?(field_name),
        clear_button_id: "#{field_name}_clear_button",
        inset: true,
        data: {
          action: "focus->overview--project-life-cycle-form#onHighlightField " \
                  "overview--project-life-cycle-form#previewForm ",
          "overview--project-life-cycle-form-target": field_name.to_s.camelize(:lower)
        },
        wrapper_data_attributes: {
          "test-selector": test_selector
        }
      }
    end

    def start_date_input(form)
      input_attributes = {
        disabled: start_date_disabled?,
        caption: start_date_caption
      }
      form.text_field **datepicker_attributes(:start_date), **input_attributes
    end

    def finish_date_input(form)
      form.text_field **datepicker_attributes(:finish_date)
    end

    def duration_input(form)
      input_attributes = {
        name: :duration,
        label: attribute_name(:duration),
        type: :number,
        inset: true,
        disabled: true,
        value: model.duration,
        trailing_visual: { text: { text: I18n.t("datetime.units.day", count: model.duration) } },
        data: { "overview--project-life-cycle-form-target": "duration" }
      }
      form.text_field **input_attributes
    end

    def autofocus?(field_name)
      # let javascipt handle focusing when rendering for preview
      return false if model.changed?

      field_name == autofocus_field_name
    end

    def autofocus_field_name
      if start_date_disabled? || (model.start_date? && !model.finish_date?)
        :finish_date
      else
        :start_date
      end
    end

    def show_clear_button?(field_name)
      case field_name
      when :start_date
        !start_date_disabled?
      when :finish_date
        true
      end
    end

    def value(field_name)
      case field_name
      when :start_date
        model.start_date || model.start_date_before_type_cast
      when :finish_date
        model.finish_date_before_type_cast
      end
    end

    def start_date_disabled?
      model.follows_previous_phase? && model.start_date.present?
    end

    def start_date_caption
      start_date_disabled? ? I18n.t("activerecord.attributes.project/phase.start_date_caption") : nil
    end

    def field_type
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
      #     when you enter a start date after today, and then open the datepicker for finish date,
      #     it will reset the start date because the finish date is set automatically to today,
      #     but the finish date can't be before the start date.
      browser.device.mobile? && !browser.safari? ? :date : :text
    end

    def placeholder
      browser.device.mobile? ? "yyyy-mm-dd" : nil
    end
  end
end
