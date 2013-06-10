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
  attr_reader :name, :url, :param, :condition, :child_menus, :last, :block

  def initialize(name, url_or_block, options)
    raise ArgumentError, "Invalid option :if for menu item '#{name}'" if options[:if] && !options[:if].respond_to?(:call)
    raise ArgumentError, "Invalid option :html for menu item '#{name}'" if options[:html] && !options[:html].is_a?(Hash)
    raise ArgumentError, "Cannot set the :parent to be the same as this item" if options[:parent] == name.to_sym
    raise ArgumentError, "Invalid option :children for menu item '#{name}'" if options[:children] && !options[:children].respond_to?(:call)

    @name = name
    @condition = options[:if]
    @param = options[:param] || :id
    @caption = options[:caption]
    @html_options = options[:html] || {}
    # Adds a unique class to each menu item based on its name
    @html_options[:class] = [@html_options[:class], @name.to_s.dasherize, 'ellipsis'].compact.join(' ')
    @child_menus = options[:children]
    @last = options[:last] || false

    if url_or_block.respond_to?(:call)
      @block = url_or_block
    else
      @block = Redmine::MenuManager::UrlAggregator.new(url_or_block, options)
    end

    super @name.to_sym
  end

  def label(locals = {})
    @block.call(locals)
  end

  # Checks if a user is allowed to access the menu item by:
  #
  # * Checking the conditions of the item
  # * Checking the url target (project only)
  def allowed?(user, project=nil)
#    @condition.call
    if condition && !condition.call(project)
      # Condition that doesn't pass
      return false
    end

    # TODO: get a better mechanism
    if block || url.try(:empty?)
      return true
    end

    if project
      return user && user.allowed_to?(url, project)
    else
      # outside a project, all menu items allowed
      return true
    end
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
