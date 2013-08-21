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
