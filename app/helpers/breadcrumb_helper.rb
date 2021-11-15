#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

module BreadcrumbHelper
  def full_breadcrumb
    breadcrumb_list(*breadcrumb_paths)
  end

  def breadcrumb(*args)
    elements = args.flatten
    elements.any? ? content_tag('p', (args.join(' &#187; ') + ' &#187; ').html_safe, class: 'op-breadcrumb') : nil
  end

  def breadcrumb_list(*args)
    elements = args.flatten
    breadcrumb_elements = [content_tag(:li,
                                       elements.shift.to_s,
                                       class: 'first-breadcrumb-element')]

    breadcrumb_elements += elements.map do |element|
      if element
        content_tag(:li,
                    h(element.to_s),
                    class: "icon4 icon-small icon-arrow-right5")
      end
    end

    content_tag(:ul, breadcrumb_elements.join.html_safe, class: 'op-breadcrumb',  'data-qa-selector': 'op-breadcrumb')
  end

  def breadcrumb_paths(*args)
    if args.nil?
      nil
    elsif args.empty?
      @breadcrumb_paths ||= [default_breadcrumb]
    else
      @breadcrumb_paths ||= []
      @breadcrumb_paths += args
    end
  end

  def show_breadcrumb
    if !!(defined? show_local_breadcrumb)
      show_local_breadcrumb
    else
      false
    end
  end
end
