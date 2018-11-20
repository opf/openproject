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
  module RolePatch
    def self.included(base)
      base.prepend InstanceMethods

      base.class_eval do
        class << self
          prepend ClassMethods
        end
      end
    end

    module ClassMethods
      def find_all_givable
        where(builtin: 0, type: 'Role').order(Arel.sql('position'))
      end
    end

    module InstanceMethods
      def setable_permissions
        setable_permissions = super
        setable_permissions -= Redmine::AccessControl.global_permissions
        setable_permissions
      end
    end
  end
end
