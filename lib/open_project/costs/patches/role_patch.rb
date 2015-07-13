#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
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

module OpenProject::Costs::Patches::RolePatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      alias_method_chain :allowed_to?, :inheritance
    end
  end

  module InstanceMethods
    # Return true if the user is allowed to do the specified action on project
    # action can be:
    # * a parameter-like Hash (eg. :controller => 'projects', :action => 'edit')
    # * a permission Symbol (eg. :edit_project)
    def allowed_to_with_inheritance?(action)
      allowed_to_with_caching(action)
    end

    private

    def allowed_to_with_caching(action)
      @allowed_to_with_inheritance ||= {}

      return @allowed_to_with_inheritance[action] if @allowed_to_with_inheritance.has_key?(action)

      @allowed_to_with_inheritance[action] = allowed_to_without_caching(action)
    end

    def allowed_to_without_caching(action)
      return true if allowed_to_without_inheritance?(action)

      if action.is_a? Hash
        # action is a parameter hash

        # check the action based on the permissions of the role and all
        # included permissions
        allowed_inherited_actions.include? "#{action[:controller]}/#{action[:action]}"
      else
        # check, if the role has one of the parent permissions granted

        permission = Redmine::AccessControl.permission(action)

        return if permission.blank?

        (permission.inherited_by + [permission]).map(&:name).detect { |parent| allowed_inherited_permissions.include? parent }

      end
    end

    def allowed_inherited_permissions
      @allowed_inherited_permissions ||= begin
        all_permissions = allowed_permissions || []
        (all_permissions | allowed_permissions.map { |sym|
          p = Redmine::AccessControl.permission(sym)
          p ? p.inherits.map(&:name) : []
        }.flatten).uniq
      end
    end

    def allowed_inherited_actions
      @actions_allowed_inherited ||= begin
        allowed_inherited_permissions.inject({}) { |actions, p| actions[p] = Redmine::AccessControl.allowed_actions(p); actions }
      end
    end
  end
end
