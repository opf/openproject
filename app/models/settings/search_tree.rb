# frozen_string_literal: true

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

module Settings
  # The settings shown in the settings search, structured like the admin menu.
  #
  # With a query, only nodes whose words, together with those of their
  # ancestors, contain every word of the query are kept, including everything
  # below them. Words are compared case insensitively and regardless of
  # punctuation, so "self registration" finds "Self-registration".
  #
  # Entities like work package types are only listed when their name matches
  # a word of the query, as there may be too many to list them all.
  class SearchTree
    Node = Data.define(:key, :label, :description, :href, :children)
    EXAMPLE_ENTITIES = 25

    # How long the tree without the entities matching a query is cached.
    # Building it is expensive (translations of all settings, an example
    # entity per kind), while it is identical between requests as long as
    # neither the settings nor the registries change. Entities added or
    # renamed within that time are found by the search all the same; only
    # the entity an attribute links to may be outdated until it expires.
    TREE_CACHE_TTL = 1.minute

    # The words of a text, decomposed and compared without accents, as users
    # may type either, like the entity names are matched.
    def self.words(text)
      text.to_s.unicode_normalize(:nfd).downcase.gsub(/\p{M}/, "").split(/[^\p{L}\p{N}]+/).compact_blank
    end

    def initialize(view_context,
                   query: nil,
                   pages: Settings::Pages.all,
                   entity_kinds: Settings::EntityKinds.all,
                   menu: Settings::Pages.admin_menu,
                   hidden_menu_items: OpenProject::Configuration.hidden_menu_items["admin_menu"] || [])
      @view_context = view_context
      @query_words = self.class.words(query)
      @pages = pages
      @pages_by_menu_item = pages.group_by(&:menu_item)
      @entity_kinds = entity_kinds
      @entity_kinds_by_menu_item = entity_kinds.group_by(&:menu_item)
      @menu = menu
      @hidden_menu_items = hidden_menu_items.map(&:to_s)
    end

    attr_reader :query_words

    def nodes
      @nodes ||= filter(assemble(@menu), [])
    end

    private

    attr_reader :view_context

    def assemble(menu_node)
      menu_node.children.filter_map do |item|
        next unless visible_menu_item?(item)

        children = [*children_of(item), *matching_nodes(item), *assemble(item)]
        Node.new(key: item.name.to_s, label: item.caption, description: nil, href: menu_item_url(item), children:)
      end
    end

    # The pages and entity kind attributes of a menu item, cached as they
    # are expensive to build. Entities matching the query are added by
    # #matching_nodes on each request.
    def children_of(item)
      children_by_item[item.name] || [*page_nodes(item), *kind_attribute_nodes(item)]
    end

    def children_by_item
      @children_by_item ||= Rails.cache.fetch(cache_key, expires_in: TREE_CACHE_TTL) { build_children_by_item }
    end

    def build_children_by_item
      {}.tap do |children_by_item|
        each_menu_item do |item|
          children_by_item[item.name] = [*page_nodes(item), *kind_attribute_nodes(item)]
        end
      end
    end

    def each_menu_item(menu_node = @menu, &)
      menu_node.children.each do |item|
        next unless visible_menu_item?(item)

        yield item
        each_menu_item(item, &)
      end
    end

    def kind_attribute_nodes(item)
      @entity_kinds_by_menu_item.fetch(item.name, []).select(&:visible?).flat_map do |kind|
        attribute_nodes(kind, kind.attributes)
      end
    end

    def matching_nodes(item)
      @entity_kinds_by_menu_item.fetch(item.name, []).select(&:visible?).flat_map do |kind|
        matching_entity_nodes(kind, kind.attributes)
      end
    end

    def page_nodes(item)
      @pages_by_menu_item.fetch(item.name, []).select(&:visible?).flat_map do |page|
        leaves = [*setting_nodes(page), *link_nodes(page)]

        if page.label && leaves.any?
          [Node.new(key: page.key.to_s,
                    label: view_context.t(page.label),
                    description: nil,
                    href: page_url(page),
                    children: leaves)]
        else
          leaves
        end
      end
    end

    def setting_nodes(page)
      page.sections.flat_map(&:visible_entries).map do |entry|
        Node.new(key: "#{page.key}-#{entry.highlight}",
                 label: entry.label(view_context),
                 description: plain_text(entry.caption(view_context)),
                 href: page_url(page, highlight: entry.highlight),
                 children: [])
      end
    end

    def link_nodes(page)
      page.visible_links.map do |link|
        Node.new(key: "#{page.key}-#{link.key}",
                 label: link.label(view_context),
                 description: nil,
                 href: view_context.instance_exec(&link.url),
                 children: [])
      end
    end

    def page_url(page, **params)
      url = page.url(@menu)
      url.is_a?(Hash) ? view_context.url_for(url.merge(params)) : menu_item_url(page.menu_node(@menu), **params)
    end

    # Mirrors Redmine::MenuManager::MenuHelper#node_url, which is private.
    def menu_item_url(item, **params)
      engine = item.engine ? view_context.public_send(item.engine) : view_context.main_app

      case item.url
      when Hash then engine.url_for(item.url.merge(params, only_path: true))
      when Symbol then engine.public_send(item.url, **params)
      else engine.url_for(item.url)
      end
    end

    def matching_entity_nodes(kind, attributes)
      kind.matching(query_words).filter_map do |entity|
        children = attribute_nodes(kind, attributes, entity)
        next if children.empty?

        Node.new(key: "#{kind.key}-#{entity.id}",
                 label: kind.name_of(entity),
                 description: nil,
                 href: view_context.instance_exec(entity, &kind.url),
                 children:)
      end
    end

    # Without an entity, attributes lead to the first entity they apply to.
    def attribute_nodes(kind, attributes, entity = nil)
      entries = attributes.filter_map do |attribute|
        target = entity || example_entities(kind).find { attribute.applies_to?(it) }
        [attribute, attribute_node(kind, attribute, target, entity)] if target && attribute.applies_to?(target)
      end

      group_attribute_nodes(kind, entity, entries)
    end

    def group_attribute_nodes(kind, entity, entries)
      entries.slice_when { |(a, _), (b, _)| a.group != b.group }.flat_map do |chunk|
        attribute = chunk.first.first
        children = chunk.map(&:last)
        attribute.group ? [group_node(kind, attribute, entity, children)] : children
      end
    end

    def attribute_node(kind, attribute, target, entity)
      Node.new(key: [kind.key, entity&.id, attribute.key].compact.join("-"),
               label: attribute.label(view_context),
               description: nil,
               href: attribute.url(target, view_context, kind.url),
               children: [])
    end

    def group_node(kind, attribute, entity, children)
      Node.new(key: [kind.key, entity&.id, attribute.group].compact.join("-"),
               label: attribute.group_label(view_context),
               description: nil,
               href: children.first.href,
               children:)
    end

    def example_entities(kind)
      @example_entities ||= {}
      @example_entities[kind.key] ||= kind.entities.limit(EXAMPLE_ENTITIES).to_a
    end

    def filter(nodes, ancestor_words)
      return nodes if query_words.empty?

      nodes.filter_map do |node|
        path_words = [*ancestor_words, *self.class.words(node.label)]
        next node if matches?([*path_words, *self.class.words(node.description)])

        children = filter(node.children, path_words)
        node.with(children:) if children.any?
      end
    end

    def matches?(words)
      query_words.all? { |query_word| words.any? { it.include?(query_word) } }
    end

    def plain_text(html)
      view_context.strip_tags(html)&.squish.presence
    end

    # The tree depends on the locale, the menu items the admin may see, the
    # state of the settings shown only in certain configurations, the
    # installed enterprise features and the registered pages and entity
    # kinds. Changed entities are covered by the expiry time alone.
    def cache_key
      [
        "settings/search-tree",
        I18n.locale,
        User.current.id,
        Setting.cache_key,
        enterprise_tokens_key,
        @hidden_menu_items.join(","),
        @pages.map(&:key).join(","),
        @entity_kinds.map(&:key).join(",")
      ].join("/")
    end

    def enterprise_tokens_key
      EnterpriseToken.active_tokens.map { "#{it.id}-#{it.updated_at.to_i}" }.sort.join(",")
    end

    def visible_menu_item?(item)
      (item.condition.nil? || item.condition.call(nil)) && @hidden_menu_items.exclude?(item.name.to_s)
    end
  end
end
