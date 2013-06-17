#-- encoding: UTF-8
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

class Redmine::MenuManager::MenuItem < Redmine::MenuManager::TreeNode
  include Redmine::I18n
  #attr_reader :name, :url, :param, :condition, :child_menus, :last, :block
  attr_accessor :name,
                :content,
                :condition

  def initialize(name, content, condition)
    @name = name
    @content = content
    @condition = condition

    super @name.to_sym, content
  end

  def label(locals = {})
    @content.call(locals)
  end

  # Checks if a user is allowed to access the menu item by:
  #
  # * Checking the conditions of the item
  # * Checking the url target (project only)
  def allowed?(locals = {})
    condition.call(locals)
#    @condition.call
#    if condition && !condition.call(project)
#      # Condition that doesn't pass
#      return false
#    end
#
#    # TODO: get a better mechanism
#    if block || url.try(:empty?)
#      return true
#    end
#
#    if project
#      return user && user.allowed_to?(url, project)
#    else
#      # outside a project, all menu items allowed
#      return true
#    end
  end

  def extract_details(locals = {})
    # support both the old and the new signature
    # old: (menu, project=nil)
    project = locals.is_a?(Project) || locals.nil? ?
                locals :
                locals[:project]

    locals = { :project => locals } if locals.is_a?(Project)

    caption = item.caption(project)

    selected = current_menu_item == item.name

    return [caption, url, selected]
  end
end
