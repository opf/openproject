require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  let(:klass) { User }

  describe :registered_allowance_evaluators do
    it { klass.registered_allowance_evaluators.include?(Costs::PrincipalAllowanceEvaluator::Costs).should be_true }
  end
end
