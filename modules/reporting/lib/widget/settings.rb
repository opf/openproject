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
  dont_cache! # Settings may change due to permissions

  def render_filter_settings
    render_widget Widget::Settings::Fieldset, @subject,
                  type: "filters" do
      render_widget Widget::Filters, @subject
    end
  end

  def render_group_by_settings
    render_widget Widget::Settings::Fieldset, @subject,
                  type: "group_by" do
      render_widget Widget::GroupBys, @subject
    end
  end

  def render_cost_types_settings
    render_widget Widget::Settings::Fieldset, @subject, type: "units" do
      render_widget Widget::CostTypes,
                    @cost_types,
                    selected_type_id: @selected_type_id
    end
  end

  def render_controls_settings
    content_tag :div, class: "form--buttons -with-button-form hide-when-print" do
      widgets = "".html_safe
      render_widget(Widget::Controls::Apply, @subject, to: widgets)
      render_widget(Widget::Controls::Save, @subject, to: widgets,
                                                      can_save: allowed_in_report?(:save, @subject, current_user))
      if allowed_in_report?(:create, @subject, current_user)
        render_widget(Widget::Controls::SaveAs, @subject, to: widgets,
                                                          can_save_as_public: allowed_in_report?(:save_as_public, @subject, current_user))
      end
      render_widget(Widget::Controls::Clear, @subject, to: widgets)
      render_widget(Widget::Controls::Delete, @subject, to: widgets,
                                                        can_delete: allowed_in_report?(:destroy, @subject, current_user))
    end
  end

  def render
    write(form_tag("#", id: "query_form", method: :post) do
      content_tag :div, id: "query_form_content" do
        # will render a setting menu for every setting.
        # To add new settings, write a new instance method render_<a name>_setting
        # and add <a name> to the @@settings_to_render list.
        content = "".html_safe
        settings_to_render.each do |setting_name|
          render_method_name = "render_#{setting_name}_settings"
          content << send(render_method_name) if respond_to? render_method_name
        end
        content
      end
    end)
  end

  def render_with_options(options, &)
    @cost_types = options.delete(:cost_types)
    @selected_type_id = options.delete(:selected_type_id)

    super
  end

  def settings_to_render
    @settings_to_render ||= %i[filter group_by cost_types controls]
  end
end
