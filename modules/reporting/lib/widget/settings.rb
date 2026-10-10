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

class Widget::Settings < Widget::Base
  param :subject, reader: false
  option :cost_types, optional: true
  option :selected_type_id, optional: true

  delegate :allowed_in_report?, to: :helpers

  def call
    primer_form_with(
      model: @subject,
      scope: :query,
      id: "query_form",
      url: "#",
      method: :post
    ) do |f|
      content_tag :div, id: "query_form_content" do
        concat render_filter_settings
        concat render_group_by_settings
        concat render_cost_types_settings
        concat render_controls_settings(f)
      end
    end
  end

  private

  def render_filter_settings
    render Widget::Settings::Fieldset.new(@subject, type: "filters") do
      render Widget::Filters.new(@subject)
    end
  end

  def render_group_by_settings
    render Widget::Settings::Fieldset.new(@subject, type: "group_by") do
      render Widget::GroupBys.new(@subject)
    end
  end

  def render_cost_types_settings
    render Widget::Settings::Fieldset.new(@subject, type: "units") do
      render Widget::CostTypes.new(@cost_types, selected_type_id: @selected_type_id)
    end
  end

  def render_controls_settings(form) # rubocop:disable Metrics/AbcSize
    render(
      Primer::Alpha::Stack.new(
        gap: :condensed,
        direction: :horizontal,
        align: :start,
        wrap: :wrap,
        role: "toolbar",
        style: "gap: 0.5rem" # override gap: :condensed
      )
    ) do
      concat render(
        Widget::Controls::Apply.new(@subject, form)
      )
      concat render(
        Widget::Controls::Save.new(@subject, form, can_save: allowed_in_report?(:save, @subject, current_user))
      )
      concat render(
        Widget::Controls::SaveAs.new(
          @subject,
          form,
          can_save_as: allowed_in_report?(:create, @subject, current_user),
          can_save_as_public: allowed_in_report?(:save_as_public, @subject, current_user)
        )
      )
      concat render(
        Widget::Controls::Clear.new(@subject, form)
      )
      concat render(
        Widget::Controls::Delete.new(@subject, form, can_delete: allowed_in_report?(:destroy, @subject, current_user))
      )
    end
  end
end
