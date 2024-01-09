#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module ReorderLinksHelper
  def reorder_links(name, url, options = {})
    method = options[:method] || :post

    content_tag(:span,
                reorder_link(name, url, 'highest', 'icon-sort-up', t(:label_sort_highest), method) +
                  reorder_link(name, url, 'higher', 'icon-arrow-up2', t(:label_sort_higher), method) +
                  reorder_link(name, url, 'lower', 'icon-arrow-down2', t(:label_sort_lower), method) +
                  reorder_link(name, url, 'lowest', 'icon-sort-down', t(:label_sort_lowest), method),
                class: 'reorder-icons')
  end

  def reorder_link(name, url, direction, icon_class, label, method)
    text = content_tag(:span,
                       label,
                       class: 'hidden-for-sighted')
    icon = content_tag(:span,
                       '',
                       class: "icon-context #{icon_class} icon-small")
    link_to(text + icon,
            url.merge("#{name}[move_to]" => direction),
            method:,
            title: label)
  end
end
