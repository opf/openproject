#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module ContextMenusHelper
  def context_menu(url)
    unless @context_menu_included
      if l(:direction) == 'rtl'
        content_for :header_tags do
          stylesheet_link_tag('context_menu_rtl')
        end
      end
      @context_menu_included = true
    end
    javascript_tag "new ContextMenu('#{ url_for(url) }')"
  end

  def context_menu_link(name, url, options={})
    options[:class] ||= ''
    if options.delete(:selected)
      options[:class] << ' icon-checked disabled'
      options[:disabled] = true
    end
    if options.delete(:disabled)
      options.delete(:method)
      options.delete(:confirm)
      options.delete(:onclick)
      options[:class] << ' disabled'
      url = '#'
    end
    link_to h(name), url, options
  end

  # TODO: need a decorator to clean this up
  def context_menu_entry(args)
    db_attribute = args[:db_attribute] || "#{args[:attribute]}_id"

    content_tag :li, :class => "folder #{args[:attribute]}" do
      ret = link_to((args[:title] || WorkPackage.human_attribute_name(args[:attribute].to_sym)), "#", :class => "context_item")

      ret += content_tag :ul do
		    args[:collection].collect do |(s, name)|
          content_tag :li do
            context_menu_link (name || s), work_packages_bulk_path(:ids => args[:updated_object_ids],
                                                                   :work_package => { db_attribute => s },
                                                                   :back_url => args[:back_url]),
                                           :method => :put,
                                           :selected => args[:selected].call(s),
                                           :disabled => args[:disabled].call(s)
          end
        end.join.html_safe
      end

      ret += content_tag :div, '', :class => "submenu"

      ret
    end
  end
end
