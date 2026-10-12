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
  class TaskForm < ApplicationForm
    form do |f|
      f.single_date_picker(
        name: :date,
        label: I18n.t("planner.task_form.date"),
        value: @date&.iso8601,
        required: true,
        leading_visual: { icon: :calendar }
      )

      f.segmented_control(
        name: :day_part,
        label: I18n.t("planner.task_form.day_part"),
        value: @day_part.to_s,
        items: DayPartField::DAY_PARTS.map { { value: it.to_s, label: I18n.t("planner.day_part.#{it}") } }
      )

      f.text_field(
        name: :subject,
        label: I18n.t("planner.task_form.subject"),
        placeholder: I18n.t("planner.task_form.placeholder"),
        required: true,
        autocomplete: "off",
        autofocus: true
      )
    end

    def initialize(date:, day_part:)
      super()
      @date = date
      @day_part = day_part
    end
  end
end
