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

  # Checks if a user is allowed to access the menu item
  def allowed?(locals = {})
    condition.call(locals)
  end
end
