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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis::Adapters::Results
  class PageSearchTreeNode
    TYPES = %i[page root wiki].freeze
    NodeKey = Data.define(:type, :identifier) do
      def self.parse(string)
        type, identifier = string.to_s.split(":", 2)
        return if identifier.blank? || TYPES.exclude?(type&.to_sym)

        new(type: type.to_sym, identifier:)
      end

      def to_s = "#{type}:#{identifier}"
    end

    attr_reader :identifier, :type, :name, :enabled, :key

    class << self
      def root
        new(identifier: "root", type: :root, name: "root")
      end

      def wiki(identifier, name)
        new(identifier:, type: :wiki, name:)
      end

      def page(identifier, name)
        new(identifier:, type: :page, name:)
      end
    end

    def initialize(identifier:, type:, name:)
      @key = NodeKey.new(type, identifier)
      @identifier = identifier
      @type = type
      @name = name
      @children = {}
    end

    def page?
      @type == :page
    end

    def wiki?
      @type == :wiki
    end

    def children = @children.values

    # @param node [PageSearchTreeNode] the node to be added
    # @raise [ArgumentError] if node isn't a {PageSearchTreeNode}
    # @return [PageSearchTreeNode] the added node or the already existing equivalent node
    def find_or_add_child(node)
      raise ArgumentError unless node.is_a? self.class

      @children[node.key] ||= node
    end

    def ==(other)
      key == other.key
    end
  end
end
