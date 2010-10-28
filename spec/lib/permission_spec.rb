require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

require 'redmine/access_control'

describe Redmine::AccessControl::Permission do
  describe "setting global" do
    describe "creating with", :new do
      before {@permission = Redmine::AccessControl::Permission.new(:perm, {:cont => [:action]}, {:global => true})}
      #before {Redmine::AccessControl::Permission.new :example_say_hello, {:example => [:say_hello]}, :public => true}
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