require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Role do
  describe "class methods" do
    describe :givable do
      before (:each) do
        #this should not be necessary once Role (in a membership) and GlobalRole have
        #a common ancestor class, e.g. Role (a new one)
        @mem_role1 = Role.create :name => "mem_role", :permissions => []
        @builtin_role1 = Role.new :name => "builtin_role1",  :permissions => []
        @builtin_role1.builtin = 3
        @builtin_role1.save
        @global_role1 = GlobalRole.create :name => "global_role1", :permissions => []
      end

      it {Role.find_all_givable.should have(1).items}
      it {Role.find_all_givable[0].should eql @mem_role1}
    end
  end

  describe "instance methods" do
    before (:each) do
      @role = Role.new
    end

    describe :setable_permissions do
      before {mock_permissions_for_setable_permissions}

      it {@role.setable_permissions.should eql([@perm1, @perm2])}
    end
  end
end