# -- copyright
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
# ++

class WorkPackages::ProgressForm < ApplicationForm
  ##
  # Primer::Forms::BaseComponent or ApplicationForm will always autofocus the
  # first input field with an error present on it. Despite this behavior being
  # a11y-friendly, it breaks the modal's UX when an invalid input field
  # is rendered.
  #
  # The reason for this is since we're implementing a "format on blur", when
  # we make a request to the server that will set an input field in an invalid
  # state and it is returned as such, any time we blur this autofocused field,
  # we'll perform another request that will still have the input in an invalid
  # state causing it to autofocus again and preventing us from leaving this
  # "limbo state".
  ##
  def before_render
    # no-op
  end

  attr_reader :work_package, :mode

  def initialize(work_package:,
                 mode: :work_based,
                 focused_field: :remaining_hours,
                 touched_field_map: {})
    super()

    @work_package = work_package
    @mode = mode
    @focused_field = focused_field_by_selection(focused_field)
    @touched_field_map = touched_field_map
    ensure_only_one_error_for_remaining_work_exceeding_work
  end

  form do |query_form|
    query_form.group(layout: :horizontal) do |group|
      if mode == :status_based
        select_status_list(group)
        text_field(group, name: :estimated_hours, label: I18n.t(:label_work))
        readonly_text_field(group, name: :remaining_hours, label: I18n.t(:label_remaining_work))

        hidden_touched_field(group, name: :status_id)
        hidden_touched_field(group, name: :estimated_hours)
      else
        text_field(group, name: :estimated_hours, label: I18n.t(:label_work))
        text_field(group, name: :remaining_hours, label: I18n.t(:label_remaining_work))
        text_field(group, name: :done_ratio, label: I18n.t(:label_percent_complete))

        hidden_touched_field(group, name: :estimated_hours)
        hidden_touched_field(group, name: :remaining_hours)
        hidden_touched_field(group, name: :done_ratio)
      end
      group.fields_for(:initial) do |builder|
        InitialValuesForm.new(builder, work_package:, mode:)
      end
    end
  end

  private

  def ensure_only_one_error_for_remaining_work_exceeding_work
    if work_package.errors.added?(:remaining_hours, :cant_exceed_work) &&
      work_package.errors.added?(:estimated_hours, :cant_be_inferior_to_remaining_work)
      error_to_delete =
        if @focused_field == :estimated_hours
          :remaining_hours
        else
          :estimated_hours
        end
      work_package.errors.delete(error_to_delete)
    end
  end

  def focused_field_by_selection(field)
    field
  end

  def select_status_list(group)
    # status selection is disabled in create forms
    disabled = work_package.new_record?

    select_field_options =
      default_field_options(:status_id)
        .merge(
          name: :status_id,
          label: I18n.t(:label_percent_complete),
          disabled:
        )

    group.select_list(**select_field_options) do |select_list|
      WorkPackages::UpdateContract.new(work_package, User.current)
                                  .assignable_statuses
                                  .each do |status| # avoid find_each to keep ordering by position
        select_list.option(
          label: "#{status.name} (#{status.default_done_ratio}%)",
          value: status.id
        )
      end
    end

    # Add a hidden field if the select field is disabled, otherwise it would not be included in the form payload
    group.hidden(name: :status_id) if disabled
  end

  def text_field(group,
                 name:,
                 label:)
    text_field_options = default_field_options(name).merge(
      name:,
      value: field_value(name),
      label:,
      caption: field_hint_message(name),
      validation_message: validation_message(name)
    )

    group.text_field(**text_field_options)
  end

  def readonly_text_field(group,
                          name:,
                          label:,
                          placeholder: true)
    text_field_options = default_field_options(name).merge(
      name:,
      value: field_value(name),
      label:,
      readonly: true,
      classes: "input--readonly",
      placeholder: ("-" if placeholder)
    )

    group.text_field(**text_field_options)
  end

  def hidden_touched_field(group, name:)
    group.hidden(name: :"#{name}_touched",
                 value: touched(name),
                 data: { "work-packages--progress--touched-field-marker-target": "touchedFieldInput",
                         "referrer-field": "work_package[#{name}]" })
  end

  def touched(name)
    @touched_field_map["#{name}_touched"] || false
  end

  def field_value(name)
    errors = @work_package.errors.where(name)
    if (user_value = errors.map { |error| error.options[:value] }.find { !_1.nil? })
      user_value
    elsif name == :done_ratio
      as_percent(@work_package.public_send(name))
    else
      DurationConverter.output(@work_package.public_send(name))
    end
  end

  def field_hint_message(field_name)
    hint = work_package.derived_progress_hints[field_name]
    return if hint.nil?

    I18n.t("work_package.progress.derivation_hints.#{field_name}.#{hint}")
  end

  def validation_message(name)
    # it's ok to take the first error only, that's how primer_view_component does it anyway.
    message = @work_package.errors.messages_for(name).first
    message&.upcase_first
  end

  def as_percent(value)
    value ? "#{value}%" : nil
  end

  def default_field_options(name)
    data = { "work-packages--progress--preview-progress-target": "progressInput",
             "work-packages--progress--touched-field-marker-target": "progressInput",
             action: "input->work-packages--progress--touched-field-marker#markFieldAsTouched" }

    if @focused_field == name
      data[:"work-packages--progress--focus-field-target"] = "fieldToFocus"
    end
    { data: }
  end
end
