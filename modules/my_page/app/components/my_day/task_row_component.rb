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

module MyDay
  class TaskRowComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    # Fixed widths keep the meta of every row in the same columns, whether it describes a quick task
    # or a planned work package.
    META_WIDTHS = { planned_for: "9rem", kind: "8rem" }.freeze

    # Ids sit before the checkbox in the lead column; longer ones are truncated.
    ID_CHARACTERS = 8
    ID_MAX_WIDTH = "#{ID_CHARACTERS}ch".freeze

    def initialize(work_package:, lead_width:, references:, view: :today, day_part: nil)
      super()
      @work_package = work_package
      @lead_width = lead_width
      @references = references
      @view = view
      @day_part = day_part
    end

    private

    attr_reader :work_package, :lead_width, :references, :view, :day_part

    def unplanned? = view == :unplanned

    # Where the Move menu can send the task: the other day parts when it is planned for today,
    # otherwise into today; and tomorrow, unless that is already its day.
    def move_targets
      targets = case view
                when :today then DayPartField::DAY_PARTS.map(&:to_s) - [day_part.to_s]
                when :unplanned then []
                else %w[today]
                end
      targets << "tomorrow" unless work_package.due_date == User.current.today + 1

      targets.map { [it, t("my_day.move_to.#{it}")] }
    end

    # Quick tasks and planned work packages share one look: the type in its colour, with own tasks
    # named as quick tasks.
    def kind_name
      planned_work_package ? planned_work_package.type.name.upcase : t("my_day.quick_task").upcase
    end

    def kind_classes
      helpers.class_names("__hl_uppercase", helpers.hl_foreground_class("type", shown_work_package.type))
    end

    def meta_cell(name)
      { mr: 2, classes: "min-width-0", style: "width: #{META_WIDTHS.fetch(name)}; flex-shrink: 0" }
    end

    def view_param = (view unless view == :today)

    def plan_path(to) = my_day_task_plan_path(work_package, to:, view: view_param)

    def plan_form_arguments = { method: :patch, data: { turbo_stream: true } }

    # The subject as text, with each visible referenced work package in place of its reference.
    def subject_parts
      work_package.subject.split(References::PATTERN).each_with_index.map do |part, index|
        index.even? ? part : references.fetch(part) { "##{part}" }
      end
    end

    # A task that only references a work package stands for that work package, so the row shows it
    # instead of the reference.
    def planned_work_package
      return @planned_work_package if defined?(@planned_work_package)

      parts = subject_parts.reject { it.is_a?(String) && it.blank? }
      @planned_work_package = parts.first if parts.one? && parts.first.is_a?(WorkPackage)
    end

    def shown_work_package = planned_work_package || work_package

    def closed? = work_package.closed?

    def meeting_command
      return @meeting_command if defined?(@meeting_command)

      @meeting_command = (MeetingCommand.for(work_package, helpers.current_user) unless closed?)
    end

    def new_meeting_path
      new_dialog_meetings_path(title: meeting_command.title, participant_ids: meeting_command.participants.map(&:id))
    end

    def toggle_label = closed? ? t("my_day.mark_open") : t("my_day.mark_done")

    def toggle_button_arguments
      {
        icon: closed? ? :"check-circle-fill" : :circle,
        color: closed? ? :success : :muted,
        scheme: :invisible,
        size: :small,
        type: :submit,
        aria: { label: toggle_label },
        test_selector: "my-day-toggle"
      }
    end

    def subject_link_arguments
      {
        href: work_package_path(shown_work_package),
        scheme: closed? ? :secondary : :primary,
        font_weight: :semibold,
        style: ("text-decoration: line-through" if closed?)
      }
    end
  end
end
