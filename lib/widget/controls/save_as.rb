#-- copyright
# ReportingEngine
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

class Widget::Controls::SaveAs < Widget::Controls
  def render
    if @subject.new_record?
      link_name = l(:button_save)
      icon = 'icon-save1'
    else
      link_name = l(:button_save_as)
      icon = 'icon-save1'
    end
    button = link_to(link_name, '#', id: 'query-icon-save-as', class: "button icon-context #{icon}")
    write(button + render_popup)
    maybe_with_help
  end

  def cache_key
    "#{super}#{@subject.name}"
  end

  def render_popup_form
    name = content_tag :p, class: 'inline-label' do
      label_tag(:query_name,
                required_field_name(Query.human_attribute_name(:name)),
                class: 'form-label -transparent') +
      text_field_tag(:query_name,
                     @subject.name,
                     required: true)
    end
    if @options[:can_save_as_public]
      box = content_tag :p, class: 'inline-label' do
        label_tag(:query_is_public,
                  Query.human_attribute_name(:is_public),
                  class: 'form-label -transparent') +
        check_box_tag(:query_is_public)
      end
      name + box
    else
      name
    end
  end

  def render_popup_buttons
    save = link_to(l(:button_save),
                   '#',
                   id: 'query-icon-save-button',
                   class: 'button -highlight icon-context icon-save1',
                   :"data-target" => url_for(action: 'create', set_filter: '1'))

    cancel = link_to(l(:button_cancel),
                     '#',
                     id: 'query-icon-save-as-cancel',
                     class: 'button icon-context icon-cancel')
    save + cancel
  end

  def render_popup
    content_tag :div, id: 'save_as_form', class: 'button_form', style: 'display:none' do
      render_popup_form + render_popup_buttons
    end
  end
end
