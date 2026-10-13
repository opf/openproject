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

module Planner
  # The fields of the "Add to-do" dialog. To plan a work package it asks for the work package instead
  # of the to-do's text and notes. For a given work package, the text is optional.
  class TaskForm < ApplicationForm
    form do |f|
      f.hidden(name: :work_package_id, value: @work_package.id) if @work_package

      if work_package_search?
        f.work_package_autocompleter(
          name: :work_package_id,
          label: I18n.t("planner.task_form.work_package"),
          required: true,
          autocomplete_options: {
            focusDirectly: true,
            openDirectly: true,
            dropdownPosition: "bottom",
            appendTo: "##{AddTodoDialogComponent::DIALOG_ID}",
            filters: work_package_filters,
            data: { test_selector: "planner-work-package-autocompleter" }
          }
        )
      end

      f.single_date_picker(
        name: :date,
        label: I18n.t("planner.task_form.date"),
        value: @date&.iso8601,
        required: true,
        leading_visual: { icon: :calendar },
        datepicker_options: { inDialog: AddTodoDialogComponent::DIALOG_ID }
      )

      f.segmented_control(
        name: :day_part,
        label: I18n.t("planner.task_form.day_part"),
        value: @day_part.to_s,
        items: DayPartField::DAY_PARTS.map { { value: it.to_s, label: I18n.t("planner.day_part.#{it}") } }
      )

      unless work_package_search?
        f.text_field(
          name: :subject,
          label: I18n.t("planner.task_form.subject"),
          **subject_hints,
          autocomplete: "off",
          autofocus: true
        )

        f.rich_text_area(
          name: :description,
          label: I18n.t("planner.task_form.description"),
          rich_text_options: { showAttachments: false, primerized: true }
        )
      end
    end

    def initialize(date:, day_part:, planner_project: nil, work_package: nil)
      super()
      @date = date
      @day_part = day_part
      @planner_project = planner_project
      @work_package = work_package
    end

    private

    def work_package_search? = @planner_project.present?

    def subject_hints
      if @work_package
        { placeholder: I18n.t("planner.task_form.note_placeholder"), caption: I18n.t("planner.task_form.note_caption") }
      else
        { placeholder: I18n.t("planner.task_form.placeholder"), required: true }
      end
    end

    # Open work packages, without the user's own to-dos.
    def work_package_filters
      [
        { name: "status", operator: Queries::Operators::OpenWorkPackages.symbol, values: [] },
        { name: "project", operator: "!", values: [@planner_project.id.to_s] }
      ]
    end
  end
end
