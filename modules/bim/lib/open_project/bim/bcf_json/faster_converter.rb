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

module OpenProject::Bim::BcfJson
  class FasterConverter
    # Convert the xml to hash as `Hash.from_xml` would, faster.
    class << self
      def xml_to_hash(xml)
        hash = Ox.load(xml, mode: :hash, symbolize_keys: false)
        make_ox_hash_look_like_loaded_by_rexml(hash)
      end

      private

      def make_ox_item_look_like_loaded_by_rexml(item)
        case item
        when Hash
          make_ox_hash_look_like_loaded_by_rexml(item)
        when Array
          make_ox_array_look_like_loaded_by_rexml(item)
        else
          item
        end
      end

      def make_ox_hash_look_like_loaded_by_rexml(hash)
        hash.transform_values! do |v|
          make_ox_item_look_like_loaded_by_rexml(v)
        end
      end

      def make_ox_array_look_like_loaded_by_rexml(array)
        if array_of_single_hash?(array)
          make_ox_hash_look_like_loaded_by_rexml(array[0])
        elsif array_of_hashes?(array)
          if array_of_similar_hashes?(array)
            # array of values like [{x: 1, y: 2}, {x: -3, y: 12}, ...]
            array.map! { make_ox_hash_look_like_loaded_by_rexml(_1) }
          else
            hash = merge_hashes_together(array)
            make_ox_hash_look_like_loaded_by_rexml(hash)
          end
        else
          array.map! do |item|
            make_ox_item_look_like_loaded_by_rexml(item)
          end
        end
      end

      def array_of_single_hash?(array)
        array.size == 1 && array[0].is_a?(Hash)
      end

      def array_of_hashes?(array)
        array.all? { _1.is_a?(Hash) }
      end

      def array_of_similar_hashes?(array)
        return false if array.empty?
        return false unless array[0].is_a?(Hash)

        keys = array[0].keys
        size = keys.size
        array.all? { |h| h.is_a?(Hash) && h.size == size && h.keys == keys }
      end

      def merge_hashes_together(array)
        head, *tail = array
        head.merge!(*tail) do |_key, oldval, newval|
          case oldval
          when Array then oldval << unwrap(newval)
          else [oldval, newval]
          end
        end
      end

      def unwrap(value)
        case value
        in [element] then element
        else value
        end
      end
    end
  end
end
