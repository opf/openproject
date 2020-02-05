#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require_dependency 'widget/base'
class Widget::Filters < ::Widget::Base
  def render
    spacer = content_tag :li, '', class: 'advanced-filters--spacer hide-when-print'

    add_filter = content_tag :li, id: 'add_filter_block', class: 'advanced-filters--add-filter hide-when-print' do
      add_filter_label = label_tag 'add_filter_select', l(:label_filter_add),
                                   class: 'advanced-filters--add-filter-label'
      add_filter_label += label_tag 'add_filter_select', I18n.t('js.filter.description.text_open_filter') + ' ' +
                                   I18n.t('js.filter.description.text_close_filter'),
                                   class: 'hidden-for-sighted'

      add_filter_value = content_tag :div, class: 'advanced-filters--add-filter-value' do
        select_tag 'add_filter_select',
                   options_for_select([['', '']] + selectables),
                   class: 'advanced-filters--select',
                   name: nil
      end

      (add_filter_label + add_filter_value).html_safe
    end

    list = content_tag :ul, id: 'filter_table', class: 'advanced-filters--filters' do
      render_filters + spacer + add_filter
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
      if f_cls.available_values.nil? || f_cls.available_values.empty?
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
    render_widget RemoveButton, f, to: html
  end
end
