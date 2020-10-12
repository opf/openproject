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

require 'tree' # gem install rubytree

class Redmine::MenuManager::TreeNode < Tree::TreeNode
  attr_reader :last_items_count

  def initialize(name, content = nil)
    @last_items_count = 0
    super
  end

  # Adds the specified child node to the receiver node.  The child node's
  # parent is set to be the receiver.  The child is added as the first child in
  # the current list of children for the receiver node.
  def prepend(child)
    raise(ArgumentError, 'Child already added') if @children_hash.has_key?(child.name)

    @children_hash[child.name]  = child
    @children = [child] + @children
    child.parent = self
    child
  end

  # Adds the specified child node to the receiver node.  The child node's
  # parent is set to be the receiver.  The child is added at the position
  # into the current list of children for the receiver node.
  def add_at(child, position)
    raise(ArgumentError, 'Child already added') if @children_hash.has_key?(child.name)

    @children_hash[child.name]  = child
    @children = @children.insert(position, child)
    child.parent = self
    child
  end

  def add_last(child)
    raise(ArgumentError, 'Child already added') if @children_hash.has_key?(child.name)

    @children_hash[child.name]  = child
    @children << child
    @last_items_count += 1
    child.parent = self
    child
  end

  # Adds the specified child node to the receiver node.  The child node's
  # parent is set to be the receiver.  The child is added as the last child in
  # the current list of children for the receiver node.
  def add(child)
    raise(ArgumentError, 'Child already added') if @children_hash.has_key?(child.name)

    @children_hash[key!(child)] = child
    position = @children.size - @last_items_count
    @children.insert(position, child)
    child.parent = self
    child
  end

  # Wrapp remove! making sure to decrement the last_items counter if
  # the removed child was a last item
  def remove!(child)
    @last_items_count -= +1 if child && child.last
    super
  end

  # Will return the position (zero-based) of the current child in
  # it's parent
  def position
    parent.children.index(self)
  end

  ##
  # Returns the key used for this child's menu entry.
  # In case there already is an entry with that key the menu entry
  # will still be added but with an updated caption appending "(duplicate)".
  #
  # It should not be possible for this to happen anyway due to validations on MenuItem.
  # But in case it does happen we don't want the whole page to be unavailable due to raising an
  # error here. Instead we mark the duplicate menu entry giving the user a chance to fix the issue.
  def key!(child)
    if @children_hash.has_key?(child.name)
      name = deduplicate(child.name, @children_hash.keys.map(&:to_s))
      child.caption = "#{child.caption} (#{I18n.t(:label_duplicate)})"

      child.name = name.to_url
    else
      child.name
    end
  end

  def deduplicate(name, existing_names)
    duplicate_count = existing_names.count { |n| n =~ /^#{name}(?: \(\d+\))?$/ }

    "#{name} (#{duplicate_count + 1})"
  end
end
