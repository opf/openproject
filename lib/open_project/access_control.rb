#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module OpenProject
  module AccessControl
    class << self
      include ::Redmine::I18n

      def map
        mapper = OpenProject::AccessControl::Mapper.new
        yield mapper
        @mapped_permissions ||= []
        @mapped_permissions += mapper.mapped_permissions
        @modules ||= []
        @modules += mapper.mapped_modules
        @project_modules_without_permissions ||= []
        @project_modules_without_permissions += mapper.project_modules_without_permissions

        clear_caches
      end

      # Get a sorted array of module names
      #
      # @param include_disabled [boolean] Whether to return all modules or only those that are active (not disabled by config)
      def sorted_module_names(include_disabled: true)
        modules
          .reject { |mod| !include_disabled && disabled_project_modules.include?(mod[:name]) }
          .sort_by { |a| [-a[:order], l_or_humanize(a[:name], prefix: 'project_module_')] }
          .map { |entry| entry[:name].to_s }
      end

      def permissions
        @permissions ||= @mapped_permissions.select(&:enabled?)
      end

      def modules
        @modules.uniq { |mod| mod[:name] }
      end

      # Returns the permission of given name or nil if it wasn't found
      # Argument should be a symbol
      def permission(action)
        if action.is_a?(Hash)
          permissions.detect { |p| p.controller_actions.include?("#{action[:controller]}/#{action[:action]}") }
        else
          permissions.detect { |p| p.name == action }
        end
      end

      # Returns the actions that are allowed by the permission of given name
      def allowed_actions(permission_name)
        perm = permission(permission_name)
        perm ? perm.controller_actions : []
      end

      def allow_actions(action_hash)
        action = "#{action_hash[:controller]}/#{action_hash[:action]}"

        permissions.select { |p| p.controller_actions.include? action }
      end

      def public_permissions
        @public_permissions ||= @mapped_permissions.select(&:public?)
      end

      def members_only_permissions
        @members_only_permissions ||= @mapped_permissions.select(&:require_member?)
      end

      def loggedin_only_permissions
        @loggedin_only_permissions ||= @mapped_permissions.select(&:require_loggedin?)
      end

      def global_permissions
        @global_permissions ||= @mapped_permissions.select(&:global?)
      end

      def available_project_modules
        project_modules
          .reject { |name| disabled_project_modules.include? name }
      end

      def disabled_project_modules
        modules
          .select { |entry| entry[:if].respond_to?(:call) && !entry[:if].call }
          .map { |entry| entry[:name].to_sym }
      end

      def project_modules
        @project_modules ||=
          @mapped_permissions
            .reject(&:global?)
            .map(&:project_module)
            .including(@project_modules_without_permissions)
            .uniq
            .compact
      end

      def modules_permissions(modules)
        @mapped_permissions.select { |p| p.project_module.nil? || modules.include?(p.project_module.to_s) }
      end

      def contract_actions_map
        @contract_actions_map ||= permissions.each_with_object({}) do |p, hash|
          next if p.contract_actions.none?

          hash[p.name] = {
            actions: p.contract_actions,
            global: p.global?,
            module_name: p.project_module,
            grant_to_admin: p.grant_to_admin?,
            public: p.public?
          }
        end
      end

      def grant_to_admin?(permission_name)
        # Parts of the application currently rely on granting not defined permissions,
        # e.g. :edit_attribute_help_texts to administrators.
        permission(permission_name).nil? || permission(permission_name).grant_to_admin?
      end

      def remove_modules_permissions(module_name)
        permissions = @mapped_permissions

        module_permissions = permissions.select { |p| p.project_module.to_s == module_name.to_s }

        clear_caches

        @mapped_permissions = permissions - module_permissions
      end

      def clear_caches
        @contract_actions_map = nil
        @loggedin_only_permissions = nil
        @members_only_permissions = nil
        @project_modules = nil
        @public_permissions = nil
        @global_permissions = nil
        @public_permissions = nil
        @permissions = nil
      end
    end
  end
end
