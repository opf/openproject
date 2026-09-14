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

module CustomFields
  module Hierarchy
    class HierarchicalItemAggregator
      class << self
        def flatten_tree_hash(hash)
          flat_list = []
          queue = [hash.merge({ depth: -1 })]

          # From the service we get a hashed tree like this:
          # {:a => {:b => {:c1 => {:d1 => {}}, :c2 => {:d2 => {}}}, :b2 => {}}}
          #
          # We flatten it depth first to this result list:
          # [:a, :b, :c1, :d1, :c2, :d2, :b2]

          while queue.any?
            current = queue.shift
            depth = current[:depth]
            item, children = current.shift

            flat_list << API::V3::CustomFields::Hierarchy::HierarchicalItemAggregate.new(item:, depth:)

            queue.unshift(current) unless current.keys == [:depth]
            queue.unshift(children.merge({ depth: depth + 1 })) unless children.empty?
          end

          flat_list
        end
      end
    end
  end
end
