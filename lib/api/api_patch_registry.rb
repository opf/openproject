#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  class APIPatchRegistry
    class << self
      def add_patch(class_name, path, &block)
        patch_maps_by_class[class_name] = {} unless patch_maps_by_class[class_name]
        patch_map = patch_maps_by_class[class_name]

        path = ":#{path}" if path.is_a?(Symbol)
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
