# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
  def initialize(work_package:,
                 mode: :work_based,
                 focused_field: :remaining_hours)
    super()

    @work_package = work_package
    @mode = mode
    @focused_field = focused_field_by_selection(focused_field) || focused_field_by_error
  end

  form do |query_form|
    query_form.group(layout: :horizontal) do |group|
      if @mode == :status_based
        select_field_options = { name: :status_id, label: I18n.t(:label_percent_complete) }.tap do |options|
          options.reverse_merge!(default_field_options(:status_id))
          options.merge!(disabled: @work_package.new_record?)
        end

        group.select_list(**select_field_options) do |select_list|
          WorkPackages::UpdateContract.new(@work_package, User.current)
                                      .assignable_statuses
                                      .find_each do |status|
            select_list.option(
              label: "#{status.name} (#{status.default_done_ratio}%)",
              value: status.id
            )
          end
        end

        render_text_field(group, name: :estimated_hours, label: I18n.t(:label_work))
        render_readonly_text_field(group, name: :remaining_hours, label: I18n.t(:label_remaining_work))
      else
        render_text_field(group, name: :estimated_hours, label: I18n.t(:label_work))
        render_text_field(group, name: :remaining_hours, label: I18n.t(:label_remaining_work),
                                 disabled: disabled_remaining_work_field?)
        render_readonly_text_field(group, name: :done_ratio, label: I18n.t(:label_percent_complete))
      end
    end
  end

  private

  def focused_field_by_selection(field)
    if field == :remaining_hours && @work_package.estimated_hours.nil?
      :estimated_hours
    else
      field
    end
  end

  # First field with an error is focused. If it's readonly or disabled, then the
  # field before it will be focused
  def focused_field_by_error
    fields = if @mode == :work_based
               %i[estimated_hours remaining_hours done_ratio]
             else
               %i[status_id estimated_hours remaining_hours]
             end

    fields.each do |field_name|
      break if @focused_field

      @focused_field = field_name if @work_package.errors.map(&:attribute).include?(field_name)
    end

    @focused_field
  end

  def render_text_field(group,
                        name:,
                        label:,
                        disabled: false,
                        placeholder: nil)
    text_field_options = {
      name:,
      value: field_value(name),
      label:,
      disabled:,
      placeholder:
    }
    text_field_options.reverse_merge!(default_field_options(name))

    group.text_field(**text_field_options)
  end

  def render_readonly_text_field(group,
                                 name:,
                                 label:,
                                 disabled: false,
                                 placeholder: true)
    text_field_options = {
      name:,
      value: field_value(name),
      label:,
      readonly: true,
      disabled:,
      classes: "input--readonly",
      placeholder: ("-" if placeholder)
    }
    text_field_options.reverse_merge!(default_field_options(name))

    group.text_field(**text_field_options)
  end

  def field_value(name)
    errors = @work_package.errors.where(name)
    if user_value = errors.map { |error| error.options[:value] }.find { !_1.nil? }
      user_value
    else
      format_to_smallest_fractional_part(@work_package.public_send(name))
    end
  end

  def format_to_smallest_fractional_part(number)
    return number if number.nil?

    number % 1 == 0 ? number.to_i : number
  end

  def default_field_options(name)
    if @focused_field == name
      { data: { "work-packages--progress--focus-field-target": "fieldToFocus" } }
    else
      {}
    end
  end

  # Remaining work field is enabled when work is set, or when there are errors
  # on fields so that they can be corrected.
  def disabled_remaining_work_field?
    @work_package.estimated_hours.nil? && @work_package.errors.empty?
  end
end
