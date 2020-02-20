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

# make sure to require Widget::Filters::Base first because otherwise
# ruby might find Base within Widget and Rails will not load it
require_dependency 'widget/filters/base'
class Widget::Filters::TextBox < Widget::Filters::Base
  def render
    label = content_tag :label,
                        "#{h(filter_class.label)} #{l(:label_filter_value)}",
                        for: "#{filter_class.underscore_name}_arg_1_val",
                        class: 'hidden-for-sighted'

    write(content_tag(:div, id: "#{filter_class.underscore_name}_arg_1", class: 'advanced-filters--filter-value') do
      label + text_field_tag("values[#{filter_class.underscore_name}]", '',
                             size: '6',
                             class: 'advanced-filters--text-field',
                             id: "#{filter_class.underscore_name}_arg_1_val",
                             :'data-filter-name' => filter_class.underscore_name)
    end)
  end
end
