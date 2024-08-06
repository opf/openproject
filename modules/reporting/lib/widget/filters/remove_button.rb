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

class Widget::Filters::RemoveButton < Widget::Filters::Base
  def render
    hidden_field = tag :input, id: "rm_#{filter_class.underscore_name}",
                               name: "fields[]", type: "hidden", value: ""
    button = content_tag(:a, href: "#", class: "filter_rem") do
      icon_wrapper("icon-close advanced-filters--remove-filter-icon", I18n.t(:description_remove_filter))
    end

    write(content_tag(:div, hidden_field + button, id: "rm_box_#{filter_class.underscore_name}",
                                                   class: "advanced-filters--remove-filter"))
  end
end
