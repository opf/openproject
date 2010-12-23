require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

require 'redmine/access_control'

describe Redmine::AccessControl::Permission do
  describe "WHEN setting global permission" do
    describe "creating with", :new do
      before {@permission = Redmine::AccessControl::Permission.new(:perm, {:cont => [:action]}, {:global => true})}
      describe :global? do
        it {@permission.global?.should be_true}
      end
    end
  end

  describe "setting non_global" do
    describe "creating with", :new do
      before {@permission = Redmine::AccessControl::Permission.new :perm, {:cont => [:action]}, {:global => false}}

      describe :global? do
        it {@permission.global?.should be_false}
      end
    end

    describe "creating with", :new do
      before {@permission = Redmine::AccessControl::Permission.new :perm, {:cont => [:action]}, {}}

      describe :global? do
        it {@permission.global?.should be_false}
      end
    end
  end

end