#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module User::Allowed
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    base.class_attribute :registered_allowance_evaluators
  end

  module InstanceMethods

    # Return true if the user is allowed to do the specified action on a specific context
    # Action can be:
    # * a parameter-like Hash (eg. :controller => '/projects', :action => 'edit')
    # * a permission Symbol (eg. :edit_project)
    # Context can be:
    # * a project : returns true if user is allowed to do the specified action on this project
    # * a group of projects : returns true if user is allowed on every project
    # * nil with options[:global] set : check if user has at least one role allowed for this action,
    #   or falls back to Non Member / Anonymous permissions depending if the user is logged
    def allowed_to?(action, context, options={})
      if action.is_a?(Hash) && action[:controller]
        if action[:controller].to_s.starts_with?("/")
          action = action.dup
          action[:controller] = action[:controller][1..-1]
        end

        action = Redmine::AccessControl.allowed_symbols(action)
      end

      if context.is_a?(Project)
        allowed_to_in_project?(action, context, options)
      elsif context.is_a?(Array)
        # Authorize if user is authorized on every element of the array
        context.present? && context.all? do |project|
          allowed_to?(action, project, options)
        end
      elsif options[:global]
        allowed_to_globally?(action, options)
      else
        false
      end
    end

    def allowed_to_in_project?(action, project, options = {})
      active_actions = filter_inactive_actions(action, project)

      return false unless project.active?
      return false if active_actions.empty?
      return true if self.admin?

      allowed_in_context(active_actions, project)
    end

    # Is the user allowed to do the specified action on any project?
    # See allowed_to? for the actions and valid options.
    def allowed_to_globally?(action, options = {})
      return true if self.admin?

      allowed_in_context(action, nil)
    end

    def allowed_in_context(action, project)
      permissions = allowance_cache.fetch(project) do
        self.allowed_roles(nil, project)
      end

      Array(action).any? { |action| permissions.any? { |role| role.allowed_to?(action.to_sym) } }
    end

    def reload(options = nil)
      allowance_cache.clear

      super
    end

    def allowed_roles(action, project = nil)
      Role.find_by_sql(User.allowed(action, project).where(id: self.id).select("roles.*").to_sql)
    end

    def allowance_cache
      @allowance_cache ||= ::User::AllowedCache.new
    end

    # Filters actions to only return those that:
    # a) do not belong to a project module OR
    # b) whoese project module is active in the project
    def filter_inactive_actions(action, project)
      action = Array(action)

      action.select do |a|
        perm = Redmine::AccessControl.permission(a)

        perm.present? &&
          (!perm.project_module ||
           project.enabled_module_names.include?(perm.project_module.to_s))
      end
    end
  end

  module ClassMethods
    def allowed(action = nil, context = nil, admin_pass: true)
      Authorization.users(project: context, permission: action, admin_pass: admin_pass)
    end
  end
end
