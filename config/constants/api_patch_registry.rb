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

module Constants
  class APIPatchRegistry
    class << self
      def add_patch(class_name, path, &block)
        patch_maps_by_class[class_name] = {} unless patch_maps_by_class[class_name]
        patch_map = patch_maps_by_class[class_name]

        path = ":#{path}" if path.is_a?(Symbol)

        if Object.const_defined?(class_name)
          raise "Adding patch #{block} to #{class_name} after it is already loaded has no effect."
        end

        patch_map[path] = [] unless patch_map[path]
        patch_map[path] << block
      end

      def patches_for(klass)
        patch_maps_by_class[klass.to_s] || {}
      end

      private

      def patch_maps_by_class
        @patch_maps_by_class ||= {}
      end
    end
  end
end
