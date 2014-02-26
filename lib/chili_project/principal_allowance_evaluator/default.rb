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

class ChiliProject::PrincipalAllowanceEvaluator::Default < ChiliProject::PrincipalAllowanceEvaluator::Base
  def granted_for_global?(candidate, action, options)
    granted = super

    granted || if candidate.is_a?(Member)
                 candidate.roles.any?{ |r| r.allowed_to?(action) }
               elsif candidate.is_a?(Role)
                  candidate.allowed_to?(action)
               end
  end

  def granted_for_project?(role, action, project, options)
    return false unless role.is_a?(Role)
    granted = super

    granted || (project.is_public? || role.member?) && role.allowed_to?(action)
  end

  def global_granting_candidates
    role = @user.logged? ?
             Role.non_member :
             Role.anonymous

    @user.memberships + [role]
  end

  def project_granting_candidates(project)
    @user.roles_for_project project
  end
end
