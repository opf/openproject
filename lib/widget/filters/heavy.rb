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

# FIXME: This basically is the MultiValues-Filter, except that we do not show
#        The select-box. This way we allow our JS to pretend this is just another
#        Filter. This is overhead...
#        But well this is again one of those temporary solutions.
# make sure to require Widget::Filters::Base first because otherwise
# ruby might find Base within Widget and Rails will not load it
require_dependency 'widget/filters/base'
class Widget::Filters::Heavy < Widget::Filters::Base
  def render
    # TODO: sometimes filter.values is of the form [["3"]] and somtimes ["3"].
    #       (using cost reporting)
    #       this might be a bug - further research would be fine
    values = filter.values.first.is_a?(Array) ? filter.values.first : filter.values
    opts = Array(values).empty? ? [] : values.map { |i| filter_class.label_for_value(i.to_i) }
    div = content_tag :div, id: "#{filter_class.underscore_name}_arg_1", class: 'advanced-filters--filter-value hidden' do
      select_options = {  :"data-remote-url" => url_for(action: 'available_values'),
                          name: "values[#{filter_class.underscore_name}][]",
                          :"data-loading" => '',
                          id: "#{filter_class.underscore_name}_arg_1_val",
                          class: 'advanced-filters--select filter-value',
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
        select_options.merge! :"data-initially-selected" => filter.values.to_json.gsub!('"', "'")
      end
      box = content_tag :select, select_options do
        render_widget Widget::Filters::Option, filter, to: '', content: opts
      end
      box
    end
    alternate_text = opts.map(&:first).join(', ').html_safe
    write(div + content_tag(:label) do
      alternate_text
    end)
  end
end
