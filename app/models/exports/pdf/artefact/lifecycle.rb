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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Exports::PDF::Artefact::Lifecycle
  def write_artefact_lifecycle
    return unless lifecycle_section?

    write_optional_page_break
    record_toc_page!("lifecycle")
    with_margin(styles.section_margins) do
      write_section_title(I18n.t("pdf_generator.dialog.include_lifecycle.label"))
      lifecycle_phases.each { |phase| write_lifecycle_phase(phase) }
    end
  end

  def lifecycle_section?
    lifecycle_phases.any? && lifecycle_allowed?
  end

  private

  def lifecycle_allowed?
    User.current.allowed_in_project?(:view_project_phases, project)
  end

  def lifecycle_phases
    @lifecycle_phases ||= project.available_phases.active.with_timeline_content.order_by_position
  end

  def write_lifecycle_phase(phase)
    write_optional_page_break
    write_lifecycle_phase_label(phase)
    with_margin(styles.project_markdown_margins) do
      style = styles.project_attribute_value
      pdf.formatted_text([style.merge({ text: lifecycle_phase_value(phase) })], style)
    end
  end

  def write_lifecycle_phase_label(phase)
    with_margin(styles.project_markdown_label_margins) do
      style = styles.project_markdown_label
      pdf.formatted_text(
        [
          { text: "■ ", color: prawn_color(phase.definition.color) },
          style.merge({ text: phase.name })
        ],
        style
      )
    end
  end

  def lifecycle_phase_value(phase)
    "#{format_lifecycle_date(phase.start_date, 'label_no_start_date')} - " \
      "#{format_lifecycle_date(phase.finish_date, 'label_no_due_date')}" \
      "#{lifecycle_gate_suffix(phase)}"
  end

  def format_lifecycle_date(date, no_date_key)
    date.present? ? format_date(date) : I18n.t(no_date_key)
  end

  def lifecycle_gate_suffix(phase)
    gates = [
      (phase.start_gate_name if phase.start_gate? && phase.start_date.present?),
      (phase.finish_gate_name if phase.finish_gate? && phase.finish_date.present?)
    ].compact
    gates.any? ? " (#{gates.join(', ')})" : ""
  end
end
