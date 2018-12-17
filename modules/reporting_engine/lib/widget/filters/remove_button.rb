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
class Widget::Filters::RemoveButton < Widget::Filters::Base
  def render
    hidden_field = tag :input, id: "rm_#{filter_class.underscore_name}",
                               name: 'fields[]', type: 'hidden', value: ''
    button = content_tag(:a, href: "#", class: "filter_rem") do
      icon_wrapper('icon-context advanced-filters--remove-filter-icon', l(:description_remove_filter))
    end

    write(content_tag(:div, hidden_field + button, id: "rm_box_#{filter_class.underscore_name}",
                                                   class: 'advanced-filters--remove-filter'))
  end
end
