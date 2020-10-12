#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::GlobalRoles::Patches
  module AccessControlPatch
    def self.included(base)
      base.send(:extend, ClassMethods)

      base.class_eval do
        class << self
          unless method_defined?(:available_project_modules_without_no_global)
            alias_method :available_project_modules_without_no_global, :available_project_modules
          end
          alias_method :available_project_modules, :available_project_modules_with_no_global
        end
      end
    end

    module ClassMethods
      def available_project_modules_with_no_global
        project_modules_with_permissions = @permissions.reject(&:global?).map(&:project_module)

        @available_project_modules = (project_modules_with_permissions + @project_modules_without_permissions)
          .uniq
          .compact
          .reject { |name| disabled_project_modules.include? name }

        available_project_modules_without_no_global
      end

      def global_permissions
        @permissions.select(&:global?)
      end
    end
  end
end

OpenProject::AccessControl.send(:include, OpenProject::GlobalRoles::Patches::AccessControlPatch)
