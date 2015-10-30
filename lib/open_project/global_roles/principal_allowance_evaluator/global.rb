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

module OpenProject
  module GlobalRoles
    module PrincipalAllowanceEvaluator
      class Global < OpenProject::PrincipalAllowanceEvaluator::Base
        def granted_for_global?(membership, action, options)
          return false unless membership.is_a?(PrincipalRole)
          granted = super

          granted || membership.role.allowed_to?(action).present?
        end

        def global_granting_candidates
          @user.principal_roles
        end
      end
    end
  end
end
