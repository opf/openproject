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

class Widget::Controls::SaveAs < Widget::Controls
  def render
    link_name =
      if @subject.new_record?
        I18n.t(:button_save)
      else
        I18n.t(:button_save_as)
      end
    button = link_to(link_name, "#", id: "query-icon-save-as", class: "button icon-context icon-save")
    write(button + render_popup)
  end

  def cache_key
    "#{super}#{@subject.name}"
  end

  # rubocop:disable Metrics/AbcSize
  def render_popup_form
    name = content_tag :p,
                       class: "form--field -required -wide-label" do
      label_tag(:query_name,
                class: "form--label -transparent") do
        Query.human_attribute_name(:name)
      end +
        content_tag(:span,
                    class: "form--field-container") do
          content_tag(:span,
                      class: "form--text-field-container") do
            text_field_tag(:query_name,
                           @subject.name,
                           required: true)
          end
        end
    end
    if @options[:can_save_as_public]
      box = content_tag :p, class: "form--field -wide-label" do
        label_tag(:query_is_public,
                  Query.human_attribute_name(:public),
                  class: "form--label -transparent") +
          content_tag(:span,
                      class: "form--field-container") do
            content_tag(:span,
                        class: "form--check-box-container") do
              check_box_tag(:query_is_public,
                            1,
                            false,
                            class: "form--check-box")
            end
          end
      end
      name + box
    else
      name
    end
  end
  # rubocop:enable Metrics/AbcSize

  def render_popup_buttons
    save_url_params = { action: "create", set_filter: "1" }
    save_url_params[:project_id] = @subject.project.id if @subject.project

    save = link_to(I18n.t(:button_save),
                   "#",
                   id: "query-icon-save-button",
                   class: "button -primary icon-context icon-save",
                   "data-target": url_for(**save_url_params))

    cancel = link_to(I18n.t(:button_cancel),
                     "#",
                     id: "query-icon-save-as-cancel",
                     class: "button icon-context icon-cancel")
    save + cancel
  end

  def render_popup
    content_tag :div, id: "save_as_form", class: "button_form", style: "display:none" do
      render_popup_form + render_popup_buttons
    end
  end
end
