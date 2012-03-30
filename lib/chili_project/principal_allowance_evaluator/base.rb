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
