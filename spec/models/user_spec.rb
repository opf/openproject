require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  let(:klass) { User }

  describe :registered_allowance_evaluators do
    it { klass.registered_allowance_evaluators.should include(OpenProject::GlobalRoles::PrincipalAllowanceEvaluator::Global) }
  end
end
