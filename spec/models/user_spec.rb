require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  let(:klass) { User }
  let(:user) { Factory.build(:user) }
  let(:project) { Factory.build(:valid_project) }

  describe :registered_allowance_evaluators do
    it { klass.registered_allowance_evaluators.include?(Costs::PrincipalAllowanceEvaluator::Costs).should be_true }
  end

  describe :allowed_to do
    describe "WITH querying for a non existent permission" do
      it { user.allowed_to?(:bogus_permission, project).should be_false }
    end
  end
end
