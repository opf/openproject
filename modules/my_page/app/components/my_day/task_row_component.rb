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

    def initialize(work_package:, lead_width:, references:, day_part: nil)
      super()
      @work_package = work_package
      @lead_width = lead_width
      @references = references
      @day_part = day_part
    end

    private

    attr_reader :work_package, :lead_width, :references, :day_part

    def inbox? = day_part.nil?

    # Where the Move menu can send the task: the other day parts today, or into today from the Inbox.
    def move_targets
      today = inbox? ? %w[today] : DayPartField::DAY_PARTS.map(&:to_s) - [day_part.to_s]

      (today + %w[tomorrow]).map { [it, t("my_day.move_to.#{it}")] }
    end

    def plan_path(to) = my_day_task_plan_path(work_package, to:, view: (:inbox if inbox?))

    def plan_form_arguments = { method: :patch, data: { turbo_stream: true } }

    # The subject as text, with each visible referenced work package in place of its reference.
    def subject_parts
      work_package.subject.split(CreateTaskService::REFERENCE).each_with_index.map do |part, index|
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
