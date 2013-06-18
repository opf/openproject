#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
