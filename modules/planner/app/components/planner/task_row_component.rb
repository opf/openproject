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
  class TaskRowComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(work_package:, references:, view: :today, day_part: nil)
      super()
      @work_package = work_package
      @references = references
      @view = view
      @day_part = day_part
    end

    private

    attr_reader :work_package, :references, :view, :day_part

    delegate :subject_parts, :planned_work_package, :meeting_command, :closed?, to: :task, private: true

    def task
      @task ||= Task.new(work_package, references:, user: User.current)
    end

    def overdue? = view == :overdue

    def completed? = view == :completed

    def draggable? = Views.sortable?(view)

    # Where the Move menu can send the task: the other day parts when it is planned for today,
    # otherwise into today; and tomorrow, unless that is already its day.
    def move_targets
      targets = case view
                when :today then DayPartField::DAY_PARTS.map(&:to_s) - [day_part.to_s]
                when :overdue then []
                else %w[today]
                end
      targets << "tomorrow" unless work_package.due_date == User.current.today + 1

      targets.map { [it, t("planner.move_to.#{it}")] }
    end

    # Overdue lists the day a task was planned for; elsewhere a planned work package shows its own
    # finish date.
    def shown_date
      overdue? ? work_package.due_date : planned_work_package&.due_date
    end

    def date_color = overdue? || shown_date < User.current.today ? :severe : :muted

    def date_title
      t("planner.planned_for", date: helpers.format_date(shown_date)) if overdue?
    end

    def view_param = Views.param(view)

    def plan_path(to) = plan_planner_task_path(work_package, to:, view: view_param)

    def plan_form_arguments = { method: :patch, data: { turbo_stream: true } }

    def delete_form_arguments = { method: :delete, data: { turbo_stream: true, turbo_confirm: delete_confirmation } }

    # Deleting a planned work package's task leaves the work package itself untouched.
    def delete_label = planned_work_package ? t("planner.remove_from_planner") : t(:button_delete)

    def delete_confirmation
      planned_work_package ? t("planner.remove_from_planner_confirmation") : t(:text_are_you_sure)
    end

    def notes
      return if notes_text.blank?

      render(Primer::Beta::Truncate.new(tag: :div, color: :muted, font_size: :small, mt: 1,
                                        test_selector: "planner-task-notes")) { notes_text }
    end

    def notes_text
      @notes_text ||= helpers.strip_tags(helpers.format_text(work_package, :description)).squish
    end

    def new_meeting_path
      new_dialog_meetings_path(title: meeting_command.title, participant_ids: meeting_command.participants.map(&:id))
    end

    def toggle_label = closed? ? t("planner.mark_open") : t("planner.mark_done")

    def toggle_button_arguments
      {
        icon: closed? ? :"check-circle-fill" : :circle,
        color: closed? ? :success : :muted,
        scheme: :invisible,
        size: :small,
        type: :submit,
        aria: { label: toggle_label },
        test_selector: "planner-toggle"
      }
    end

    def subject_link_arguments
      {
        href: work_package_path(planned_work_package || work_package),
        target: "_blank",
        scheme: closed? ? :secondary : :primary,
        font_weight: :semibold,
        style: ("text-decoration: line-through" if closed?)
      }
    end
  end
end
