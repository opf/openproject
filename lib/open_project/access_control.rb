#-- encoding: UTF-8

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

module OpenProject
  module AccessControl
    class << self
      include ::Redmine::I18n

      def map
        mapper = OpenProject::AccessControl::Mapper.new
        yield mapper
        @permissions ||= []
        @permissions += mapper.mapped_permissions
        @modules ||= []
        @modules += mapper.mapped_modules
        @project_modules_without_permissions ||= []
        @project_modules_without_permissions += mapper.project_modules_without_permissions
      end

      # Get a sorted array of module names
      #
      # @param include_disabled [boolean] Whether to return all modules or only those that are active (not disabled by config)
      def sorted_module_names(include_disabled = true)
        modules
          .reject { |mod| !include_disabled && disabled_project_modules.include?(mod[:name]) }
          .sort_by { |a| [-a[:order], l_or_humanize(a[:name], prefix: 'project_module_')] }
          .map { |entry| entry[:name].to_s }
      end

      def permissions
        @permissions
      end

      def modules
        @modules.uniq { |mod| mod[:name] }
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
        @available_project_modules ||= begin
          (@permissions.map(&:project_module) + @project_modules_without_permissions)
            .uniq
            .compact
            .reject { |name| disabled_project_modules.include? name }
        end
      end

      def disabled_project_modules
        @disabled_project_modules ||= modules
          .select { |entry| entry[:if].respond_to?(:call) && !entry[:if].call }
          .map { |entry| entry[:name].to_sym }
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
  end
end
