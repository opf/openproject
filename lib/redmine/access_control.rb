#-- encoding: UTF-8
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

module Redmine
  module AccessControl
    class << self
      def map
        mapper = Mapper.new
        yield mapper
        @permissions ||= []
        @permissions += mapper.mapped_permissions
        @project_modules_without_permissions ||= []
        @project_modules_without_permissions += mapper.project_modules_without_permissions
      end

      def permissions
        @permissions
      end

      # Returns the permission of given name or nil if it wasn't found
      # Argument should be a symbol
      def permission(name)
        permissions.detect { |p| p.name == name }
      end

      # Returns the actions that are allowed by the permission of given name
      def allowed_actions(permission_name)
        perm = permission(permission_name)
        perm ? perm.actions : []
      end

      def allow_actions(action_hash)
        action = "#{action_hash[:controller]}/#{action_hash[:action]}"

        permissions.select { |p| p.actions.include? action }
      end

      def public_permissions
        @public_permissions ||= @permissions.select(&:public?)
      end

      def members_only_permissions
        @members_only_permissions ||= @permissions.select(&:require_member?)
      end

      def loggedin_only_permissions
        @loggedin_only_permissions ||= @permissions.select(&:require_loggedin?)
      end

      def available_project_modules
        @available_project_modules ||= (
            @permissions.map(&:project_module) + @project_modules_without_permissions
        ).uniq.compact
      end

      def modules_permissions(modules)
        @permissions.select { |p| p.project_module.nil? || modules.include?(p.project_module.to_s) }
      end

      def remove_modules_permissions(module_name)
        permissions = @permissions

        module_permissions = permissions.select { |p| p.project_module.to_s == module_name.to_s }

        clear_caches

        @permissions = permissions - module_permissions
      end

      def clear_caches
        @available_project_modules = nil
        @public_permissions = nil
        @members_only_permissions = nil
        @loggedin_only_permissions = nil
      end
    end

    class Mapper
      def permission(name, hash, options = {})
        options.merge!(project_module: @project_module)
        mapped_permissions << Permission.new(name, hash, options)
      end

      def project_module(name, _options = {})
        if block_given?
          @project_module = name
          yield self
          @project_module = nil
        else
          project_modules_without_permissions << name
        end
      end

      def mapped_permissions
        @permissions ||= []
      end

      def project_modules_without_permissions
        @project_modules_without_permissions ||= []
      end
    end

    class Permission
      attr_reader :name, :actions, :project_module

      def initialize(name, hash, options)
        @name = name
        @actions = []
        @public = options[:public] || false
        @require = options[:require]
        @project_module = options[:project_module]
        hash.each do |controller, actions|
          if actions.is_a? Array
            @actions << actions.map { |action| "#{controller}/#{action}" }
          else
            @actions << "#{controller}/#{actions}"
          end
        end
        @actions.flatten!
      end

      def public?
        @public
      end

      def require_member?
        @require && @require == :member
      end

      def require_loggedin?
        @require && (@require == :member || @require == :loggedin)
      end
    end
  end
end
