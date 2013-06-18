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

class ChiliProject::PrincipalAllowanceEvaluator::Base
  def initialize(user)
    @user = user
  end

  def granted_for_global? candidate, action, options
    false
  end

  def denied_for_global? candidate, action, options
    false
  end

  def granted_for_project? candidate, action, project, options = {}
    false
  end

  def denied_for_project? candidate, action, project, options = {}
    false
  end

  def global_granting_candidates
    []
  end

  def project_granting_candidates project
    []
  end
end
