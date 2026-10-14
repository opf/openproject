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
  # Registry of the kinds of entities, such as work package types, whose
  # attributes are found by the settings search.
  #
  # A kind is listed below its admin menu entry with one node per attribute,
  # leading to the attribute on the first entity's page. Entities whose name
  # matches the query are listed as well, each with its own attribute nodes.
  #
  # Attributes link to the kind's `url` unless they have their own (e.g. for
  # another tab), and highlight their form `field` there, given as the field
  # name or as `name=value` for one of several inputs of the same name.
  # Labels and URLs are lambdas evaluated in the view context, URLs receiving
  # the entity. An `if` lambda receiving the entity limits the entities an
  # attribute applies to and a `group` label nests attributes below a common node.
  #
  # @example
  #   Settings::EntityKinds.draw do
  #     kind :statuses, menu_item: :statuses, scope: -> { Status.order(:position) },
  #                     url: ->(status) { edit_status_path(status) } do
  #       attribute :color, label: -> { Status.human_attribute_name(:color) }, field: "status[color_id]"
  #     end
  #   end
  module EntityKinds
    MATCH_LIMIT = 5

    class Attribute
      attr_reader :key, :field, :group

      def initialize(key, label:, url: nil, field: nil, group: nil, **options)
        @key = key
        @label = label
        @url = url
        @field = field
        @group = group
        @condition = options[:if]
      end

      def label(view_context)
        resolve(@label, view_context)
      end

      def group_label(view_context)
        resolve(group, view_context)
      end

      def applies_to?(entity)
        @condition.nil? || @condition.call(entity)
      end

      def url(entity, view_context, default_url)
        url_proc = @url || default_url
        url = view_context.instance_exec(entity, &url_proc)
        return url unless field

        separator = url.include?("?") ? "&" : "?"
        "#{url}#{separator}#{{ highlight: field }.to_query}"
      end

      private

      def resolve(text, view_context)
        case text
        when Proc then view_context.instance_exec(&text)
        when Symbol then view_context.t(text)
        else text
        end
      end
    end

    class Kind
      attr_reader :key, :menu_item, :url

      def initialize(key, menu_item:, scope:, url:, name: :name)
        @key = key
        @menu_item = menu_item
        @scope = scope
        @url = url
        @name = name
        @attributes = []
        @attribute_sources = []
      end

      def attribute(key, **)
        @attributes << Attribute.new(key, **)
      end

      def attributes_from(&block)
        @attribute_sources << block
      end

      def attributes
        [*@attributes, *@attribute_sources.flat_map(&:call)]
      end

      def entities
        @scope.call
      end

      def name_of(entity)
        entity.public_send(@name)
      end

      def matching(words, limit: MATCH_LIMIT)
        return entities.none if words.empty?

        column = entities.arel_table[@name]
        entities.where(column.matches_any(words.map { "%#{ActiveRecord::Base.sanitize_sql_like(it)}%" })).limit(limit)
      end
    end

    class << self
      def draw(&)
        instance_exec(&)
      end

      def kind(key, **, &)
        registry[key.to_sym] = Kind.new(key.to_sym, **).tap { it.instance_exec(&) if block_given? }
      end

      def fetch(key)
        registry.fetch(key.to_sym)
      end

      def all
        registry.values
      end

      private

      def registry
        @registry ||= {}
      end
    end
  end
end
