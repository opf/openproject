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

class Widget::Table::EntryTable < Widget::Table
  include ReportingHelper

  FIELDS = %i[user_id activity_id entity_gid comments logged_by_id project_id].freeze

  def render
    content = content_tag :div, class: "generic-table--container -with-footer" do
      content_tag :div, class: "generic-table--results-container" do
        table = content_tag :table, class: "generic-table",
                                    id: "sortable-table" do
          concat colgroup
          concat head
          concat foot
          concat body
        end
        table
      end
    end
    write content
  end

  def colgroup
    content_tag :colgroup do
      concat content_tag(:col, "")
      FIELDS.each do
        concat content_tag(:col, "")
      end
      concat content_tag(:col, "")
      concat content_tag(:col, "")
      concat content_tag(:col, "")
    end
  end

  def head_column_field(field)
    head_column(label_for(field))
  end

  def head_column(label)
    content_tag(:th) do
      content_tag(:div, class: "generic-table--sort-header-outer") do
        content_tag(:div, class: "generic-table--sort-header") do
          content_tag(:span, label)
        end
      end
    end
  end

  # rubocop:disable Metrics/AbcSize
  def head
    content_tag :thead do
      content_tag :tr do
        concat head_column_field(:spent_on)
        concat head_column(I18n.t("label_time")) if with_times_column?
        FIELDS.map do |field|
          concat head_column_field(field)
        end
        concat head_column(cost_type.try(:unit_plural) || I18n.t(:units))
        concat head_column(CostEntry.human_attribute_name(:costs))
        hit = false
        @subject.each_direct_result do |result|
          next if hit

          if entry_for(result).editable_by? User.current
            concat content_tag(:th, class: "unsortable") {
              content_tag(:div, "", class: "generic-table--empty-header")
            }
            hit = true
          end
        end
      end
    end
  end

  def foot
    content_tag :tfoot do
      content_tag :tr do
        main_columns = with_times_column? ? 2 : 1
        if show_result(@subject, 0) == show_result(@subject)
          concat content_tag(:td, "", colspan: FIELDS.size + main_columns + 1)
          concat content_tag(:td) {
            concat content_tag(:div,
                               show_result(@subject),
                               class: "result generic-table--footer-outer")
          }
        else
          concat content_tag(:td, "", colspan: FIELDS.size + main_columns)
          concat content_tag(:td) {
            concat content_tag(:div,
                               show_result(@subject),
                               class: "inner generic-table--footer-outer")
          }
          concat content_tag(:td) {
            concat content_tag(:div,
                               show_result(@subject, 0),
                               class: "result generic-table--footer-outer")
          }
        end
        concat content_tag(:th, "", class: "unsortable")
      end
    end
  end

  def body_column_field(field, result)
    content_tag(:td, show_field(field, result.fields[field.to_s]),
                "raw-data": raw_field(field, result.fields[field.to_s]),
                class: "left")
  end

  def body
    content_tag :tbody do
      rows = ActiveSupport::SafeBuffer.new
      @subject.each_direct_result do |result|
        rows << (content_tag(:tr) do
          concat body_column_field(:spent_on, result)
          if with_times_column?
            concat content_tag :td, spent_on_time_representation(result.start_timestamp, result["units"].to_f),
                               class: "start_time right",
                               "raw-data": result.start_timestamp.to_s
          end
          FIELDS.each do |field|
            concat body_column_field(field, result)
          end
          concat content_tag :td, show_result(result, result.fields["cost_type_id"].to_i),
                             class: "units right",
                             "raw-data": result.units
          concat content_tag :td,
                             show_result(result, 0),
                             class: "currency right",
                             "raw-data": result.real_costs
          concat content_tag :td, icons(result)
        end)
      end
      rows
    end
  end

  def icons(result)
    icons = ""
    with_project(result.fields["project_id"]) do
      if entry_for(result).editable_by? User.current
        if controller_for(result.fields["type"]) == "costlog"
          icons = link_to(icon_wrapper("icon-context icon-edit", I18n.t(:button_edit)),
                          action_for(result, action: "edit"),
                          class: "no-decoration-on-hover",
                          title: I18n.t(:button_edit))

          icons << link_to(icon_wrapper("icon-context icon-delete", I18n.t(:button_delete)),
                           action_for(result, action: "destroy")
                             .reverse_merge(authenticity_token: form_authenticity_token),
                           data: { turbo_method: :delete, turbo_confirm: I18n.t(:text_are_you_sure) },
                           class: "no-decoration-on-hover",
                           title: I18n.t(:button_delete))
        else
          icons = angular_component_tag("opce-time-entry-trigger-actions",
                                        data: { entry: result["id"] })
        end
      end
    end
    icons
  end

  # rubocop:enable Metrics/AbcSize

  def labour_query?
    cost_type_filter = @subject.filters.detect { |f| f.is_a?(CostQuery::Filter::CostTypeId) }
    cost_type_filter&.values&.first.to_i == -1
  end

  def with_times_column?
    Setting.allow_tracking_start_and_end_times && labour_query?
  end
end
