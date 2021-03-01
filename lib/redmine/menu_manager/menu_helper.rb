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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Redmine::MenuManager::MenuHelper
  include ::Redmine::MenuManager::TopMenuHelper
  include ::Redmine::MenuManager::WikiMenuHelper
  include AccessibilityHelper

  # Returns the current menu item name
  def current_menu_item
    controller.current_menu_item
  end

  # Renders the application main menu
  def render_main_menu(menu, project = nil)
    # Fall back to project_menu when project exists (not during project creation)
    if menu.nil? && project && project.persisted?
      menu = :project_menu
    end

    if !menu
      # For some global pages such as home
      nil
    elsif menu == :project_menu && project && project.persisted?
      build_wiki_menus(project)
      render_menu(:project_menu, project)
    elsif menu == :wp_query_menu
      render_menu(:application_menu, project)
    else
      render_menu(menu, project)
    end
  end

  def render_menu(menu, project = nil)
    links = []

    menu_items = first_level_menu_items_for(menu, project) do |node|
      @menu = menu
      links << render_menu_node(node, project)
    end

    first_level = any_item_selected?(select_leafs(menu_items)) || !current_menu_item_part_of_menu?(menu, project)
    classes = first_level ? 'open' : 'closed'

    links.empty? ? nil : content_tag('ul', safe_join(links, "\n"), class: 'menu_root ' + classes)
  end

  def select_leafs(items)
    items.select { |item| item.children.empty? }
  end

  ##
  # Render a dropdown menu item with the given MenuItem children.
  # Caller may add additional items through the optional block.
  # Remaining options are passed through to +render_menu_dropdown+.
  def render_menu_dropdown_with_items(label:, label_options:, items:, options: {})
    selected = any_item_selected?(items)
    label_node = render_drop_down_label_node(label, selected, label_options)

    render_menu_dropdown(label_node, options) do
      items.each do |item|
        concat render_menu_node(item)
      end

      concat(yield) if block_given?
    end
  end

  ##
  # Render a dropdown menu item with arbitrary content.
  # As these are not menu-items, the whole dropdown may never be marked selected.
  # Available options:
  # menu_item_class: Additional classes for the menu item li wrapper
  # drop_down_class: Additional classes for the hidden drop down
  def render_menu_dropdown(label_node, options = {}, &block)
    content_tag :li, class: "top-menu-dropdown #{options[:menu_item_class]} drop-down" do
      concat(label_node)
      concat(content_tag(:ul,
                         style: 'display:none',
                         id: options[:drop_down_id],
                         class: 'menu-drop-down-container ' + options.fetch(:drop_down_class, ''),
                         &block))
    end
  end

  def render_drop_down_label_node(label, selected, options = {})
    options[:title] ||= selected ? t(:description_current_position) + label : label
    options[:aria] = { haspopup: 'true' }
    options[:class] = "top-menu-dropdown--link #{options[:class]} #{selected ? 'selected' : ''}"

    link_to('', options) do
      concat(op_icon(options[:icon])) if options[:icon]
      concat(you_are_here_info(selected).html_safe)
      concat(content_tag(:span, label, class: 'button--dropdown-text'))
      concat('<i class="button--dropdown-indicator"></i>'.html_safe) unless options.key?(:icon)
    end
  end

  def render_menu_node(node, project = nil)
    return '' unless allowed_node?(node, User.current, project)

    if node.has_children? || !node.child_menus.nil?
      render_menu_node_with_children(node, project)
    else
      render_single_node_or_partial(node, project)
    end
  end

  def render_menu_node_with_children(node, project = nil)
    html_options = { data: { name: node.name } }

    if node_or_children_selected?(node)
      html_options[:class] = 'open'
    end
    content_tag :li, html_options do
      # Standard children
      standard_children_list = node.children.map do |child|
        render_menu_node(child, project) if visible_node?(@menu, child)
      end.join.html_safe

      # Unattached children
      unattached_children_list = render_unattached_children_menu(node, project)

      # Parent
      node = [render_single_menu_node(node, project)]

      # add children
      unless standard_children_list.empty?
        node << content_tag(:ul, standard_children_list, class: 'main-menu--children')
      end
      unless unattached_children_list.blank?
        node << content_tag(:ul, unattached_children_list, class: 'main-menu--children unattached')
      end

      safe_join(node, "\n")
    end
  end

  def render_single_menu_node(item, project = nil)
    caption, url, selected = extract_node_details(item, project)

    link_text = ''.html_safe
    link_text << op_icon(item.icon(project)) if item.icon(project).present?
    link_text << content_tag(:span,
                             class: "menu-item--title ellipsis #{item.badge(project).present? ? '-has-badge' : ''}",
                             lang: menu_item_locale(item)) do
      ''.html_safe + caption + badge_for(item)
    end
    link_text << ' '.html_safe + op_icon(item.icon_after) if item.icon_after.present?
    html_options = item.html_options(selected: selected)
    html_options[:title] ||= selected ? t(:description_current_position) + caption : caption

    link_to link_text, url, html_options
  end

  def current_menu_item_part_of_menu?(menu, project = nil)
    return true if no_menu_item_wiki_prefix? || wiki_prefix?

    all_menu_items_for(menu, project).each do |node|
      return true if node.name == current_menu_item
    end

    false
  end

  def first_level_menu_items_for(menu, project = nil, &block)
    menu_items_for(Redmine::MenuManager.items(menu).root.children, menu, project, &block)
  end

  private

  # Returns a list of unattached children menu items
  def render_unattached_children_menu(node, project)
    return nil unless node.child_menus

    ''.tap do |child_html|
      unattached_children = node.child_menus.call(project)
      # Tree nodes support #each so we need to do object detection
      if unattached_children.is_a? Array
        unattached_children.each do |child|
          child_html << content_tag(:li, render_unattached_menu_item(child, project))
        end
      else
        raise Redmine::MenuManager::MenuError, ':child_menus must be an array of MenuItems'
      end
    end.html_safe
  end

  def render_unattached_menu_item(menu_item, project)
    unless menu_item.is_a? Redmine::MenuManager::MenuItem
      raise Redmine::MenuManager::MenuError,
            ':child_menus must be an array of MenuItems'
    end

    if User.current.allowed_to?(menu_item.url(project), project)
      link_to(menu_item.caption,
              menu_item.url(project),
              menu_item.html_options)
    end
  end

  def render_single_node_or_partial(node, project)
    if node.partial
      content_tag('li', render(partial: node.partial), class: "partial", data: { name: node.name })
    else
      content_tag('li', render_single_menu_node(node, project), data: { name: node.name })
    end
  end

  def all_menu_items_for(menu, project = nil)
    menu_items_for(Redmine::MenuManager.items(menu).root, menu, project)
  end

  def node_or_children_selected?(node)
    node_selected?(node) || any_item_selected?(node.children)
  end

  def node_selected?(item)
    current_menu_item == item.name || no_wiki_menu_item_selected?(item)
  end

  def extract_node_details(node, project = nil)
    url = allowed_node_url(node, project)
    caption = node.caption(project)
    selected = node_or_children_selected?(node)

    [caption, url, selected]
  end

  def allowed_node_url(node, project)
    user = User.current
    if !(node_action_allowed? node, project, user) && node.allow_deeplink?
      allowed_child = node.children.find { |child| node_action_allowed? child, project, user }
      if allowed_child
        node_url allowed_child, project
      end
    else
      node_url node, project
    end
  end

  def node_url(node, project)
    engine = node_engine(node)

    case node.url(project)
    when Hash
      engine.url_for(project.nil? ? node.url(project) : { node.param => project }.merge(node.url(project)))
    when Symbol
      engine.send(node.url(project))
    else
      engine.url_for(node.url(project))
    end
  end

  def menu_items_for(iteratable, menu, project = nil)
    items = []
    iteratable.each do |node|
      next if node.name == :root

      if allowed_node?(node, User.current, project) && visible_node?(menu, node)
        items << node
        if block_given?
          yield node
        end
      end
    end

    items
  end

  # Checks if a user is allowed to access the menu item by:
  #
  # * Checking the conditions of the item
  # * Checking the url target (project only)
  def allowed_node?(node, user, project)
    if node.condition && !node.condition.call(project)
      # Condition that doesn't pass
      return false
    end

    if project
      allowed_project_node?(node, project, user)
    else
      # outside a project, all menu items allowed
      true
    end
  end

  def allowed_project_node?(node, project, user)
    if node_action_allowed?(node, project, user)
      true
    elsif node.allow_deeplink?
      node.children.any? do |child|
        node_action_allowed?(child, project, user)
      end
    else
      false
    end
  end

  def node_action_allowed?(node, project, user)
    user&.allowed_to?(node.url(project), project)
  end

  def visible_node?(menu, node)
    @hidden_menu_items ||= OpenProject::Configuration.hidden_menu_items
    if @hidden_menu_items.length.positive?
      hidden_nodes = @hidden_menu_items[menu.to_s] || []
      !hidden_nodes.include? node.name.to_s
    else
      true
    end
  end

  def node_engine(node)
    node.engine ? send(node.engine) : main_app
  end

  def no_wiki_menu_item_selected?(item)
    no_menu_item_wiki_prefix? &&
      item.name == current_menu_item.to_s.gsub(/^no-menu-item-/, '').to_sym
  end

  def no_menu_item_wiki_prefix?
    current_menu_item.to_s.match? /^no-menu-item-wiki-/
  end

  def wiki_prefix?
    current_menu_item.to_s.match? /^wiki-/
  end

  def badge_for(item)
    badge = ''.html_safe

    if item.badge(@project).present?
      badge += content_tag('span', I18n.t(item.badge(@project)), class: 'main-item--badge')
    end
    badge
  end

  def any_item_selected?(items)
    items.any? { |item| item.name == current_menu_item }
  end
end
