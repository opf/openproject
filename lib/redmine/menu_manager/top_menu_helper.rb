#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine::MenuManager::TopMenuHelper

  def render_top_menu(locals = { })
    locals[:controller] = self.controller

    links = Redmine::MenuManager.menu_items_for(:'global/top', locals[:project]).map do |node|
              render_menu_node(node, locals.dup)
            end

    links.empty? ? nil : content_tag('ul', links.join("\n").html_safe, :class => "menu_root", :id => "account-nav")
  end
end
