require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  let(:klass) { User }

  describe :registered_allowance_evaluators do
    it { klass.registered_allowance_evaluators.include?(GlobalRoles::PrincipalAllowanceEvaluator::Global).should be_true }
  end
end
