#-- encoding: UTF-8
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

class Redmine::MenuManager::MenuItem < Redmine::MenuManager::TreeNode
  include Redmine::I18n
  attr_reader :name,
              :param,
              :icon_after,
              :context,
              :condition,
              :parent,
              :child_menus,
              :last,
              :partial,
              :engine

  def initialize(name, url, options)
    raise ArgumentError, "Invalid option :if for menu item '#{name}'" if options[:if] && !options[:if].respond_to?(:call)
    raise ArgumentError, "Invalid option :html for menu item '#{name}'" if options[:html] && !options[:html].is_a?(Hash)
    raise ArgumentError, 'Cannot set the :parent to be the same as this item' if options[:parent] == name.to_sym
    raise ArgumentError, "Invalid option :children for menu item '#{name}'" if options[:children] && !options[:children].respond_to?(:call)
    @name = name
    @url = url
    @condition = options[:if]
    @param = options[:param] || :id
    @icon = options[:icon]
    @icon_after = options[:icon_after]
    @caption = options[:caption]
    @context = options[:context]
    @html_options = options[:html].nil? ? {} : options[:html].dup
    # Adds a unique class to each menu item based on its name
    @html_options[:class] = [
      @html_options[:class], "#{@name.to_s.dasherize}-menu-item", 'ellipsis'
    ].compact.join(' ')
    @parent = options[:parent]
    @child_menus = options[:children]
    @last = options[:last] || false
    @partial = options[:partial]
    @badge = options[:badge]
    @engine = options[:engine]
    @allow_deeplink = options[:allow_deeplink]
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

  def caption=(new_caption)
    @caption = new_caption
  end

  def icon(project = nil)
    if @icon.is_a?(Proc)
      @icon.call(project).to_s
    else
      @icon
    end
  end

  def icon=(new_icon)
    @icon = new_icon
  end

  def badge(project = nil)
    if @badge.is_a?(Proc)
      @badge.call(project).to_s
    else
      @badge
    end
  end

  def badge=(new_badge)
    @badge = new_badge
  end

  def url(project = nil)
    if @url.is_a?(Proc)
      @url.call(project)
    else
      @url
    end
  end

  def url=(new_url)
    @url = new_url
  end

  # Allow special case that the user is not allowed to see the parent node but at least one children.
  # In that case, parent and the children are shown.
  # The parent's url is then changed to the children's url.
  def allow_deeplink?
    @allow_deeplink
  end

  def allow_deeplink=(allow_deeplink)
    @allow_deeplink = allow_deeplink
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
    if old_condition.respond_to?(:call)
      @condition = -> (project) { old_condition.call(project) && new_condition.call(project) }
    else
      @condition = -> (project) { new_condition.call(project) }
    end
  end
end
