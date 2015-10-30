#-- copyright
# OpenProject Global Roles Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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
        @available_project_modules = (
            @permissions.reject(&:global?).collect(&:project_module) +
            @project_modules_without_permissions
        ).uniq.compact
        available_project_modules_without_no_global
      end

      def global_permissions
        @permissions.select(&:global?)
      end
    end
  end
end

Redmine::AccessControl.send(:include, OpenProject::GlobalRoles::Patches::AccessControlPatch)
