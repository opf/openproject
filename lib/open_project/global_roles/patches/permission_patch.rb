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

require_dependency 'redmine/access_control'

module OpenProject::GlobalRoles::Patches
  module PermissionPatch
    def self.included(base)
      base.prepend(InstanceMethods)
    end

    module InstanceMethods
      def initialize(name, hash, options)
        @global = options[:global] || false

        super(name, hash, options)
      end

      def global?
        @global || global_require
      end

      def global=(bool)
        @global = bool
      end

      private

      def global_require
        @require && @require == :global
      end
    end
  end
end

Redmine::AccessControl::Permission.send(:include, OpenProject::GlobalRoles::Patches::PermissionPatch)
