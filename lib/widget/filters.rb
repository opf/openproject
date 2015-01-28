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

class Widget::Filters < Widget::Base
  def render
    add_filter = content_tag :li, id: 'add_filter_block', class: 'advanced-filters--add-filter' do
      add_filter_label = label_tag 'add_filter_select', l(:label_filter_add),
                                   class: 'advanced-filters--add-filter-label'

      add_filter_value = content_tag :div, class: 'advanced-filters--add-filter-value' do
        value = select_tag 'add_filter_select',
                           options_for_select([['', '']] + selectables),
                           class: 'form--select -small',
                           name: nil
        value += maybe_with_help icon: { class: 'filter-icon' },
                                 tooltip: { class: 'filter-tip' },
                                 instant_write: false # help associated with this kind of Widget

        value
      end

      (add_filter_label + add_filter_value).html_safe
    end

    list = content_tag :ul, id: 'filter_table', class: 'advanced-filters--filters' do
      render_filters + add_filter
    end

    write content_tag(:div, list)
  end

  def selectables
    filters = engine::Filter.all
    filters.sort_by(&:label).select(&:selectable?).map do |filter|
      [filter.label, filter.underscore_name]
    end
  end

  def render_filters
    active_filters = @subject.filters.select(&:display?)
    engine::Filter.all.select(&:selectable?).map do |filter|
      opts = { id: "filter_#{filter.underscore_name}",
               class: "#{filter.underscore_name} advanced-filters--filter",
               :"data-filter-name" => filter.underscore_name }
      active_instance = active_filters.detect { |f| f.class == filter }
      if active_instance
        opts[:"data-selected"] = true
      else
        opts[:style] = 'display:none'
      end
      content_tag :li, opts do
        render_filter filter, active_instance
      end
    end.join.html_safe
  end

  def render_filter(f_cls, f_inst)
    f = f_inst || f_cls
    html = ''.html_safe
    render_widget Label, f, to: html
    render_widget Operators, f, to: html
    if f_cls.heavy?
      render_widget Heavy, f, to: html
    elsif engine::Operator.string_operators.all? { |o| f_cls.available_operators.include? o }
      render_widget TextBox, f, to: html
    elsif engine::Operator.time_operators.all? { |o| f_cls.available_operators.include? o }
      render_widget Date, f, to: html
    elsif engine::Operator.integer_operators.all? { |o| f_cls.available_operators.include? o }
      if f_cls.available_values.empty?
        render_widget TextBox, f, to: html
      else
        render_widget MultiValues, f, to: html, lazy: true
      end
    else
      if f_cls.is_multiple_choice?
        render_widget MultiChoice, f, to: html
      else
        render_widget MultiValues, f, to: html, lazy: true
      end
    end
    render_filter_help f, to: html
    render_widget RemoveButton, f, to: html
  end

  # #Renders help for a filter (chainable)
  def render_filter_help(filter, options = {})
    html = content_tag :td, width: '25px' do
      if filter.help_text # help associated with the chainable this Widget represents
        render_widget Widget::Controls::Help, filter.help_text
      end
    end
    if canvas = options[:to]
      canvas << "\n" << html
    else
      html
    end
  end
end
