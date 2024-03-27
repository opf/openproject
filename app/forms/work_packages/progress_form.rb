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

  def focused_field_by_selection(field)
    if field == :remaining_hours && @work_package.remaining_hours.nil?
      :estimated_hours
    else
      field
    end
  end

  # Primer form fields don't seem to be accepting
  # autofocus on a field that has an inline error on it.
  # This method remains here to ensure that down-the-line
  # when this is fixed, we get this behavior for free as am
  # accessibility boost.
  def focused_field_by_error
    %i[estimated_hours remaining_hours done_ratio].each do |field_name|
      break if @focused_field

      @focused_field = field_name if @work_package.errors.map(&:attribute).include?(field_name)
    end

    @focused_field
  end

  form do |query_form|
    if @mode == :status_based
      query_form.group(layout: :horizontal) do |group|
        group.select_list(
          name: :status_id,
          label: "% Complete"
        ) do |select_list|
          Status.find_each do |status|
            select_list.option(
              label: "#{status.name} (#{status.default_done_ratio}%)",
              value: status.id
            )
          end
        end

        group.text_field(
          name: :estimated_hours,
          label: "Work",
          autofocus: @focused_field == :estimated_hours
        )

        group.text_field(
          name: :remaining_hours,
          label: "Remaining work",
          readonly: true,
          classes: "input--readonly",
          autofocus: @focused_field == :remaining_hours,
          placeholder: "-"
        )
      end
    else
      query_form.group(layout: :horizontal) do |group|
        group.text_field(
          name: :estimated_hours,
          label: "Work",
          autofocus: @focused_field == :estimated_hours
        )

        group.text_field(
          name: :remaining_hours,
          label: "Remaining work",
          autofocus: @focused_field == :remaining_hours,
          disabled: @work_package.estimated_hours.nil?
        )

        group.text_field(
          name: :done_ratio,
          label: "% Complete",
          readonly: true,
          classes: "input--readonly",
          autofocus: @focused_field == :done_ratio,
          placeholder: "-"
        )
      end
    end
  end
end
