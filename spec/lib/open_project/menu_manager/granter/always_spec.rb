require 'spec_helper'

describe Redmine::MenuManager::Granter::Always do
  let(:klass) { Redmine::MenuManager::Granter::Always }

  describe "call" do
    it "should always return true" do
      klass.call.should be_true
    end
  end
end
