#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2010-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class OpenProject::GlobalRoles::PrincipalAllowanceEvaluator::Global < ChiliProject::PrincipalAllowanceEvaluator::Base

  def granted_for_global? membership, action, options
    return false unless membership.is_a?(PrincipalRole)
    granted = super

    granted ||= membership.role.allowed_to?(action).present?
  end

  def global_granting_candidates
    @user.principal_roles
  end
end
