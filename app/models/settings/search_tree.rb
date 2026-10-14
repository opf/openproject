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

    def self.words(text)
      text.to_s.downcase.split(/[^\p{L}\p{N}]+/).compact_blank
    end

    def initialize(view_context,
                   query: nil,
                   pages: Settings::Pages.all,
                   entity_kinds: Settings::EntityKinds.all,
                   menu: Settings::Pages.admin_menu,
                   hidden_menu_items: OpenProject::Configuration.hidden_menu_items["admin_menu"] || [])
      @view_context = view_context
      @query_words = self.class.words(query)
      @pages_by_menu_item = pages.group_by(&:menu_item)
      @entity_kinds_by_menu_item = entity_kinds.group_by(&:menu_item)
      @menu = menu
      @hidden_menu_items = hidden_menu_items.map(&:to_s)
    end

    attr_reader :query_words

    def nodes
      @nodes ||= filter(build(@menu), [])
    end

    private

    attr_reader :view_context

    def build(menu_node)
      menu_node.children.filter_map do |item|
        next unless visible_menu_item?(item)

        children = [*page_nodes(item), *entity_kind_nodes(item), *build(item)]
        next if children.empty?

        Node.new(key: item.name.to_s, label: item.caption, description: nil, href: view_context.url_for(item.url), children:)
      end
    end

    def page_nodes(item)
      @pages_by_menu_item.fetch(item.name, []).select(&:visible?).flat_map do |page|
        leaves = setting_nodes(page)

        if page.label && leaves.any?
          [Node.new(key: page.key.to_s,
                    label: view_context.t(page.label),
                    description: nil,
                    href: view_context.url_for(page.url(@menu)),
                    children: leaves)]
        else
          leaves
        end
      end
    end

    def setting_nodes(page)
      page.sections.flat_map(&:visible_entries).map do |entry|
        Node.new(key: "#{page.key}-#{entry.name}",
                 label: entry.label(view_context),
                 description: plain_text(entry.caption(view_context)),
                 href: view_context.url_for(page.url(@menu).merge(highlight: entry.name)),
                 children: [])
      end
    end

    def entity_kind_nodes(item)
      @entity_kinds_by_menu_item.fetch(item.name, []).flat_map do |kind|
        attributes = kind.attributes
        [*attribute_nodes(kind, attributes), *matching_entity_nodes(kind, attributes)]
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

    def visible_menu_item?(item)
      (item.condition.nil? || item.condition.call(nil)) && @hidden_menu_items.exclude?(item.name.to_s)
    end
  end
end
