#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

class Redmine::MenuManager::MenuItem < Redmine::MenuManager::TreeNode
  include Redmine::I18n
  attr_reader :name, :url, :param, :condition, :parent, :child_menus, :last

  def initialize(name, url, options)
    raise ArgumentError, "Invalid option :if for menu item '#{name}'" if options[:if] && !options[:if].respond_to?(:call)
    raise ArgumentError, "Invalid option :html for menu item '#{name}'" if options[:html] && !options[:html].is_a?(Hash)
    raise ArgumentError, 'Cannot set the :parent to be the same as this item' if options[:parent] == name.to_sym
    raise ArgumentError, "Invalid option :children for menu item '#{name}'" if options[:children] && !options[:children].respond_to?(:call)
    @name = name
    @url = url
    @condition = options[:if]
    @param = options[:param] || :id
    @caption = options[:caption]
    @html_options = options[:html] || {}
    # Adds a unique class to each menu item based on its name
    @html_options[:class] = [
      @html_options[:class], "#{@name.to_s.dasherize}-menu-item", 'ellipsis'
    ].compact.join(' ')
    @parent = options[:parent]
    @child_menus = options[:children]
    @last = options[:last] || false
    super @name.to_sym
  end

  def caption(project = nil)
    if @caption.is_a?(Proc)
      c = @caption.call(project).to_s
      c = @name.to_s.humanize if c.blank?
      c
    else
      if @caption.nil?
        l_or_humanize(name, prefix: 'label_')
      else
        @caption.is_a?(Symbol) ? l(@caption) : @caption
      end
    end
  end

  def html_options(options = {})
    if options[:selected]
      o = @html_options.dup
      o[:class] += ' selected'
      o
    else
      @html_options
    end
  end

  def add_condition(new_condition)
    raise ArgumentError, 'Condition needs to be callable' unless new_condition.respond_to?(:call)
    old_condition = @condition
    @condition = -> (project) { old_condition.call(project) && new_condition.call(project) }
  end
end
