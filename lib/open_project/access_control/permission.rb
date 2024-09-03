#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
    class Permission
      attr_reader :name,
                  :controller_actions,
                  :contract_actions,
                  :project_module,
                  :dependencies,
                  :permissible_on

      # @param public [Boolean] when true, the permission is granted to anybody
      # having at least one role in a project, regardless of the role's
      # permissions.
      def initialize(name,
                     hash,
                     permissible_on:,
                     public: false,
                     require: nil,
                     enabled: true,
                     project_module: nil,
                     contract_actions: [],
                     grant_to_admin: true,
                     dependencies: nil)
        @name = name
        @public = public
        @require = require
        @permissible_on = Array(permissible_on)
        @enabled = enabled
        @project_module = project_module
        @contract_actions = contract_actions
        @grant_to_admin = grant_to_admin
        @dependencies = Array(dependencies)

        @controller_actions = hash.map do |controller, actions|
          if actions.is_a? Array
            actions.map { |action| "#{controller}/#{action}" }
          else
            "#{controller}/#{actions}"
          end
        end.flatten
      end

      def public?
        @public
      end

      def work_package?
        permissible_on? :work_package
      end

      def project?
        permissible_on? :project
      end

      def global?
        permissible_on? :global
      end

      def project_query?
        permissible_on? :project_query
      end

      def permissible_on?(context_type)
        # Sometimes the context_type passed in is a decorated object.
        # Most of the times, this would then be an 'EagerLoadingWrapper' instance.
        # We need to unwrap the object to get the actual object.
        # Checking for `context_type.is_a?(SimpleDelegator)` fails for unknown reasons.
        context_type = context_type.__getobj__ if context_type.class.ancestors.include?(SimpleDelegator)

        context_symbol = case context_type
                         when WorkPackage
                           :work_package
                         when Project
                           :project
                         when ::ProjectQuery
                           :project_query
                         when Symbol
                           context_type
                         when nil
                           :global
                         else
                           raise "Unknown context: #{context_type}"
                         end

        @permissible_on.include?(context_symbol)
      end

      def grant_to_admin?
        @grant_to_admin
      end

      def require_member?
        @require && @require == :member
      end

      def require_loggedin?
        @require && (@require == :member || @require == :loggedin)
      end

      def enabled?
        if @enabled.respond_to?(:call)
          @enabled.call
        else
          @enabled
        end
      end

      def disable!
        @enabled = false
      end

      def enable!
        @enabled = true
      end
    end
  end
end
