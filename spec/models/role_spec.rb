require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Role do
  def mock_permissions_for_setable_permissions
    @public_perm = mock_permissions(true, false)
    @perm1 = mock_permissions(false, false)
    @perm2 = mock_permissions(false, false)
    @global_perm = mock_permissions(false, true)

    @perms = [@public_perm, @perm1, @global_perm, @perm2]
    Redmine::AccessControl.stub!(:permissions).and_return(@perms)
    Redmine::AccessControl.stub!(:public_permissions).and_return([@public_perm])
    Redmine::AccessControl.stub!(:global_permissions).and_return([@global_perm])
  end

  def mock_permissions(is_public, is_global)
    permission = mock_model Redmine::AccessControl::Permission
    permission.stub!(:public?).and_return(is_public)
    permission.stub!(:global?).and_return(is_global)
    permission
  end



  describe "class methods" do
    describe :givable do
      before (:each) do
        #this should not be necessary once Role (in a membership) and GlobalRole have
        #a common ancestor class, e.g. Role (a new one)
        @mem_role1 = Role.create :name => "mem_role1", :permissions => []
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