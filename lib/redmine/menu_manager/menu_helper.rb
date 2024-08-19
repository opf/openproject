#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

module Redmine::MenuManager::MenuHelper
  include ::Redmine::MenuManager::TopMenuHelper
  include ::Redmine::MenuManager::WikiMenuHelper
  include AccessibilityHelper
  include IconsHelper
  include IconsHelper

  delegate :current_menu_item, to: :controller

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
    else
      render_menu(menu, project)
    end
  end

  def render_menu(menu, project = nil)
    links = []
    @menu = menu
    menu_items = first_level_menu_items_for(menu, project) do |node|
      links << render_menu_node(node, project)
    end

    first_level = any_item_selected?(select_leafs(menu_items)) || !current_menu_item_part_of_menu?(menu, project)
    classes = first_level ? "open" : "closed"

    if links.present?
      content_tag("ul",
                  safe_join(links, "\n"),
                  class: "menu_root #{classes}",
                  data: {
                    "menus--main-target": "root"
                  })
    end
  end

  def select_leafs(items)
    items.select { |item| item.children.empty? }
  end

  ##
  # Render a dropdown menu item with the given MenuItem children.
  # Caller may add additional items through the optional block.
  # Remaining options are passed through to +render_menu_dropdown+.
  def render_menu_dropdown_with_items(label:, label_options:, items:, options: {}, project: nil)
    selected = any_item_selected?(items)
    label_node = render_drop_down_label_node(label, selected, label_options)

    options[:drop_down_class] = "op-menu #{options.fetch(:drop_down_class, '')}"
    render_menu_dropdown(label_node, options) do
      items.each do |item|
        concat render_menu_node(item, project)
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
  def render_menu_dropdown(label_node, options = {}, &)
    content_tag :li, class: "op-app-menu--item op-app-menu--item_has-dropdown #{options[:menu_item_class]}" do
      concat(label_node)
      concat(content_tag(:ul,
                         style: "display:none",
                         id: options[:drop_down_id],
                         class: "op-app-menu--dropdown #{options.fetch(:drop_down_class, '')}",
                         &))
    end
  end

  def render_drop_down_label_node(label, selected, options = {})
    options[:title] ||= selected ? t(:description_current_position) + label : label
    options[:aria] = { haspopup: "true" }
    options[:class] = "op-app-menu--item-action #{options[:class]} #{selected ? 'selected' : ''}"
    options[:span_class] = "op-app-menu--item-title #{options[:span_class]}"

    link_to("#", options) do
      concat(op_icon(options[:icon])) if options[:icon]
      concat(you_are_here_info(selected).html_safe)
      concat(content_tag(:span, label, class: options[:span_class]))
      concat('<i class="op-app-menu--item-dropdown-indicator button--dropdown-indicator"></i>'.html_safe) unless options.key?(:icon)
    end
  end

  def render_menu_node(node, project = nil)
    return "" unless allowed_node?(node, User.current, project)

    if node.has_children? || !node.child_menus.nil?
      render_menu_node_with_children(node, project)
    else
      render_single_node_or_partial(node, project)
    end
  end

  def render_menu_node_with_children(node, project = nil)
    content_tag :li, menu_node_options(node) do
      items = [
        render_wrapped_menu_parent_node(node, project),
        render_visible_children_list(node, project),
        render_unattached_children_list(node, project)
      ]

      safe_join(items, "\n")
    end
  end

  def render_wrapped_menu_parent_node(node, project)
    html_id = node.html_options[:id] || node.name
    content_tag(:div, class: "main-item-wrapper", id: "#{html_id}-wrapper") do
      concat render_single_menu_node(node, project)
      concat render_menu_toggler(node.name)
    end
  end

  def render_wrapped_single_node(node, project)
    html_id = node.html_options[:id] || node.name
    content_tag(:div, class: "main-item-wrapper", id: "#{html_id}-wrapper") do
      render_single_menu_node(node, project)
    end
  end

  def render_menu_toggler(node_name)
    content_tag(:button,
                class: "toggler main-menu-toggler",
                type: :button,
                data: {
                  action: "menus--main#descend",
                  test_selector: "main-menu-toggler--#{node_name}"
                }) do
      render(Primer::Beta::Octicon.new("arrow-right", size: :small))
    end
  end

  def render_visible_children_list(node, project)
    items = node
      .children
      .map { |child| render_menu_node(child, project) if visible_node?(@menu, child) }

    if items.present?
      capture do
        concat render_children_menu_header(node, project)
        concat content_tag(:ul, safe_join(items, "\n"), class: "main-menu--children")
      end
    end
  end

  def render_unattached_children_list(node, project)
    items = render_unattached_children_menu(node, project)

    if items.present?
      capture do
        concat render_children_menu_header(node, project)
        concat content_tag(:ul, items, class: "main-menu--children unattached")
      end
    end
  end

  def render_children_menu_header(node, project)
    caption, url, = extract_node_details(node, project)

    content_tag(:div, class: "main-menu--children-menu-header") do
      concat render_children_back_up_link(node)
      concat link_to(caption, url, class: "main-menu--parent-node ellipsis")
    end
  end

  def render_children_back_up_link(node)
    content_tag(
      :a,
      render(Primer::Beta::Octicon.new("arrow-left", size: :small)),
      title: I18n.t("js.label_up"),
      class: "main-menu--arrow-left-to-project",
      data: {
        action: "menus--main#ascend",
        "tour-selector": "main-menu--arrow-left_#{node.name}"
      }
    )
  end

  # rubocop:disable Metrics/AbcSize
  def render_single_menu_node(item, project = nil, menu_class = "op-menu")
    caption, url, selected = extract_node_details(item, project)
    shown_in_main_menu = menu_class == "op-menu"

    link_text = "".html_safe

    if item.icon(project).present?
      link_text << render(Primer::Beta::Octicon.new(
                            icon: item.icon,
                            mr: shown_in_main_menu ? 3 : 0,
                            size: shown_in_main_menu ? :small : :medium
                          ))
    end

    badge_class = item.badge(project:).present? ? " #{menu_class}--item-title_has-badge" : ""

    link_text << content_tag(:span,
                             class: "#{menu_class}--item-title#{badge_class}",
                             lang: menu_item_locale(item)) do
      title_text = "".html_safe + content_tag(:span, caption, class: "ellipsis") + badge_for(item)
      if item.enterprise_feature.present? && !EnterpriseToken.allows_to?(item.enterprise_feature)
        title_text << ("".html_safe + render(Primer::Beta::Octicon.new(icon: "op-enterprise-addons",
                                                                       classes: "upsale-colored",
                                                                       ml: 2)))
      end
      title_text
    end

    if item.icon_after.present?
      link_text << ("".html_safe + render(Primer::Beta::Octicon.new(icon: item.icon_after, classes: "trailing-icon")))
    end

    html_options = item.html_options(selected:)
    html_options[:title] ||= selected ? t(:description_current_position) + caption : caption
    html_options[:class] = "#{html_options[:class]} #{menu_class}--item-action"
    html_options["data-test-selector"] = "#{menu_class}--item-action"
    html_options["target"] = "_blank" if item.icon_after.present? && item.icon_after == "link-external"

    link_to link_text, url, html_options
  end

  # rubocop:enable Metrics/AbcSize

  def current_menu_item_part_of_menu?(menu, project = nil)
    return true if no_menu_item_wiki_prefix? || wiki_prefix?

    all_menu_items_for(menu, project).each do |node|
      return true if node.name == current_menu_item
    end

    false
  end

  def first_level_menu_items_for(menu, project = nil, &)
    menu_items_for(Redmine::MenuManager.items(menu, project).root.children, menu, project, &)
  end

  private

  def menu_node_options(node)
    {
      class: node_or_children_selected?(node) ? "open" : nil,
      data: {
        name: node.name,
        "menus--main-target": "item"
      }
    }.compact
  end

  # Returns a list of unattached children menu items
  def render_unattached_children_menu(node, project)
    return nil unless node.child_menus

    "".tap do |child_html|
      unattached_children = node.child_menus.call(project)
      # Tree nodes support #each so we need to do object detection
      if unattached_children.is_a? Array
        unattached_children.each do |child|
          child_html << content_tag(:li, render_unattached_menu_item(child, project))
        end
      else
        raise Redmine::MenuManager::MenuError, ":child_menus must be an array of MenuItems"
      end
    end.html_safe
  end

  def render_unattached_menu_item(menu_item, project)
    unless menu_item.is_a? Redmine::MenuManager::MenuItem
      raise Redmine::MenuManager::MenuError,
            ":child_menus must be an array of MenuItems"
    end

    if User.current.allowed_in_project?(menu_item.url(project), project)
      link_to(menu_item.caption,
              menu_item.url(project),
              menu_item.html_options)
    end
  end

  def render_single_node_or_partial(node, project)
    content =
      if node.partial
        render(partial: node.partial, locals: { name: node.name, parent_name: node.parent.name })
      else
        render_single_menu_node(node, project)
      end

    content_tag("li",
                content,
                class: "#{node.partial ? 'partial ' : ''}main-menu-item",
                data: { name: node.name })
  end

  def all_menu_items_for(menu, project = nil)
    menu_items_for(Redmine::MenuManager.items(menu, project).root, menu, project)
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
    when NilClass
      "#"
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
    return true if node.skip_permissions_check?
    return false if user.nil?

    url = node.url(project)
    return true unless url

    begin
      user.allowed_based_on_permission_context?(url, project:)
    rescue Authorization::UnknownPermissionError, Authorization::IllegalPermissionContextError
      false
    end
  end

  def visible_node?(menu, node)
    @hidden_menu_items ||= OpenProject::Configuration.hidden_menu_items
    if @hidden_menu_items.length.positive?
      hidden_nodes = @hidden_menu_items[menu.to_s] || []
      hidden_nodes.exclude? node.name.to_s
    else
      true
    end
  end

  def node_engine(node)
    node.engine ? send(node.engine) : main_app
  end

  def no_wiki_menu_item_selected?(item)
    no_menu_item_wiki_prefix? &&
      item.name == current_menu_item.to_s.gsub(/^no-menu-item-/, "").to_sym
  end

  def no_menu_item_wiki_prefix?
    current_menu_item.to_s.match? /^no-menu-item-wiki-/
  end

  def wiki_prefix?
    current_menu_item.to_s.match? /^wiki-/
  end

  def badge_for(item)
    badge = "".html_safe

    key = item.badge(project: @project)
    if badge.present?
      badge += content_tag("span", I18n.t(key), class: "main-item--badge")
    end
    badge
  end

  def any_item_selected?(items)
    items.any? { |item| item.name == current_menu_item }
  end
end
