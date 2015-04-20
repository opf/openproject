#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

class User
  module Authorization
    def self.included(base)
      base.extend(ClassMethods)

      base.private_class_method :eager_load_for_project_authorization
      base.private_class_method :reset_associations_eager_loaded_for_project_authorization
    end

    module ClassMethods
      def authorize_within(project, &block)
        base_scope = current_scope || scoped
        auth_scope = eager_load_for_project_authorization(base_scope, project)

        returned_users = block.call(auth_scope)

        unless returned_users.is_a?(Array) && returned_users.all? { |e| e.is_a?(User) }
          raise ArgumentError, 'Expect an array of users to be returned by the block'
        end

        reset_associations_eager_loaded_for_project_authorization(returned_users, project)

        returned_users
      end

      def eager_load_for_project_authorization(base_scope, project)
        registered_allowance_evaluators.inject(base_scope) do |scope, evaluator|
          evaluator_scope = evaluator.eager_load_for_project_authorization(project)

          if evaluator_scope.nil?
            scope
          else
            scope.merge(evaluator_scope)
          end
        end
      end

      # Prevent harmful side effects by the limited loading
      # (e.g. WHERE members.project_id = 1) of associations for the project
      # authorization.
      def reset_associations_eager_loaded_for_project_authorization(users, project)
        auth_scope = eager_load_for_project_authorization(scoped, project)

        to_clear = reflect_on_all_associations.map(&:name) &
                   auth_scope.eager_load_values.map(&:keys).flatten.uniq

        users.each do |user|
          # For reasons I don't understand #reset does not clear
          # the loaded flag on the association. Documentation says it should.
          user.association_cache.except!(*to_clear)
        end

        users
      end
    end
  end
end
