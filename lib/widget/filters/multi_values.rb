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

# make sure to require Widget::Filters::Base first because otherwise
# ruby might find Base within Widget and Rails will not load it
require_dependency 'widget/filters/base'
class Widget::Filters::MultiValues < Widget::Filters::Base
  def render
    write(content_tag(:div, id: "#{filter_class.underscore_name}_arg_1", class: 'advanced-filters--filter-value') do
      select_options = {  :"data-remote-url" => url_for(action: 'available_values'),
                          style: 'vertical-align: top;', # FIXME: Do CSS
                          name: "values[#{filter_class.underscore_name}][]",
                          :"data-loading" => @options[:lazy] ? 'ajax' : '',
                          id: "#{filter_class.underscore_name}_arg_1_val",
                          class: 'form--select filter-value',
                          :"data-filter-name" => filter_class.underscore_name,
                          multiple: 'multiple' }
      # multiple will be disabled/enabled later by JavaScript anyhow.
      # We need to specify multiple here because of an IE6-bug.
      if filter_class.has_dependent?
        all_dependents = filter_class.all_dependents.map(&:underscore_name).to_json
        select_options.merge! :"data-all-dependents" => all_dependents.gsub!('"', "'")
        next_dependents = filter_class.dependents.map(&:underscore_name).to_json
        select_options.merge! :"data-next-dependents" => next_dependents.gsub!('"', "'")
      end
      # store selected value(s) in data-initially-selected if this filter is a dependent
      # of another filter, as we have to restore values manually in the client js
      if (filter_class.is_dependent? || @options[:lazy]) && !Array(filter.values).empty?
        select_options.merge! :"data-initially-selected" =>
          filter.values.to_json.gsub!('"', "'") || '[' + filter.values.map { |v| "'#{v}'" }.join(',') + ']'
      end
      select_options.merge! :"data-dependent" => true if filter_class.is_dependent?
      box_content = ''.html_safe
      label = label_tag "#{filter_class.underscore_name}_arg_1_val",
                        h(filter_class.label) + ' ' + l(:label_filter_value),
                        class: 'hidden-for-sighted'

      box = content_tag :select, select_options, id: "#{filter_class.underscore_name}_select_1" do
        render_widget Widget::Filters::Option, filter, to: box_content unless @options[:lazy]
      end
      plus = content_tag :a, href: 'javascript:', class: 'form-label filter_multi-select -transparent',
                             :"data-filter-name" => filter_class.underscore_name,
                             title: l(:description_multi_select) do
              content_tag :span, '', class: 'icon-context icon-button icon-add icon4', title: l(:label_enable_multi_select) do
                content_tag :span, l(:label_enable_multi_select), class: 'hidden-for-sighted'
              end
      end

      content_tag(:span, class: 'inline-label') do
        label + box + plus
      end
    end)
  end
end
