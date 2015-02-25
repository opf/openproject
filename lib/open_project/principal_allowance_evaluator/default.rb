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

class OpenProject::PrincipalAllowanceEvaluator::Default < OpenProject::PrincipalAllowanceEvaluator::Base
  def granted_for_global?(candidate, action, options)
    granted = super

    granted || if candidate.is_a?(Member)
                 candidate.roles.any? { |r| r.allowed_to?(action) }
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

  def self.eager_load_for_project_authorization(project)
    User
      .scoped
      .eager_load(members: [:project, :roles])
      .where(members: { project_id: project.id })
  end

  def project_granting_candidates(project)
    if @user.memberships.loaded?
      @user.roles_for_project(project)
    else
      roles_for_project(project)
    end
  end

  def roles_for_project(project)
    # This is a copy of User#roles_for_project.  As we cannot use User's
    # memberships association for joining (the projects.status condition is not
    # fit to be used as part of the ON clause as projects is not joined at this
    # point), and User#roles_for_project relies on this association, we are
    # forced to use User's members association.

    # No role on archived projects
    return [] unless project && project.active?

    if @user.logged?
      # Find project membership
      member = @user.members.detect { |m| m.project_id == project.id }

      if member
        member.roles
      else
        [Role.non_member]
      end
    else
      [Role.anonymous]
    end
  end
end
