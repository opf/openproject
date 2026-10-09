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

class OpenProject::JournalFormatter::ProjectPhaseDates < JournalFormatter::Base
  def render(key, values, options = { html: true })
    html = options[:html]

    step = Project::Phase.find_by(id: key[/\d+/])
    return unless step

    phase_message = format_phase_message(step:, values:, html:)
    return unless phase_message

    start_gate_message = format_start_gate_message(step:, values:, html:)
    finish_gate_message = format_finish_gate_message(step:, values:, html:)

    if start_gate_message && finish_gate_message
      I18n.t("activity.project_phase.phase_and_both_gates", phase_message:, start_gate_message:, finish_gate_message:)
    elsif (gate_message = start_gate_message || finish_gate_message)
      I18n.t("activity.project_phase.phase_and_one_gate", phase_message:, gate_message:)
    else
      phase_message
    end
  end

  private

  def format_phase_message(step:, values:, html:)
    name = step.definition.name
    from, to = values.map { format_date_range(it) }

    format_message(name:, from:, to:, html:)
  end

  def format_start_gate_message(step:, values:, html:)
    return unless step.definition.start_gate

    values = values.map { it&.begin }
    return if values[0] == values[1]

    name = step.definition.start_gate_name
    from, to = values.map { format_date(it) }

    format_message(name:, from:, to:, html:)
  end

  def format_finish_gate_message(step:, values:, html:)
    return unless step.definition.finish_gate

    values = values.map { it&.end }
    return if values[0] == values[1]

    name = step.definition.finish_gate_name
    from, to = values.map { format_date(it) }

    format_message(name:, from:, to:, html:)
  end

  def format_date_range(date_range)
    "#{format_date(date_range.begin)} - #{format_date(date_range.end)}" if date_range
  end

  def format_message(name:, from:, to:, html:)
    date_change_message = format_date_change(from:, to:, html:)
    return unless date_change_message

    label = html ? content_tag(:strong, name) : name

    "#{label} #{date_change_message}"
  end

  def format_date_change(from:, to:, html:)
    if from && to
      I18n.t("activity.project_phase.changed_date", from:, to:)
    elsif to
      I18n.t("activity.project_phase.added_date", date: to)
    elsif from
      date = html ? content_tag("del", from) : from

      I18n.t("activity.project_phase.removed_date", date:)
    end
  end
end
