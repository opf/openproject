class Costs::PrincipalAllowanceEvaluator::Costs < ChiliProject::PrincipalAllowanceEvaluator::Base
  def granted_for_global? membership, action, options
    granted = super

    allowed_for_role = Proc.new do |role|
      @user.allowed_for_role(action, nil, role, [@user], options.merge({:for => @user, :global => true}))
    end

    granted ||= if membership.is_a?(Member)
                  membership.roles.any?(&allowed_for_role)
                elsif membership.is_a?(Role)
                  allowed_for_role.call(membership)
                end
  end

  def granted_for_project? role, action, project, options
    (project.is_public? || role.member?) &&
      @user.allowed_for_role(action, project, role, [@user], options.reverse_merge({:for => @user}))
  end

  def denied_for_project? role, action, project, options
    action.is_a?(Symbol) &&
      options[:for] && options[:for] != @user &&
      Redmine::AccessControl.permission(action).granular_for
  end
end
