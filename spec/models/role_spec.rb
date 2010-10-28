require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Role do
  def mock_permissions(is_public, is_global)
    permission = mock_model Redmine::AccessControl::Permission
    permission.stub!(:public?).and_return(is_public)
    permission.stub!(:global?).and_return(is_global)
    permission
  end

  before (:each) do
    @role = Role.new
  end

  describe :setable_permissions do
    before (:each) do
      @public_perm = mock_permissions(true, false)
      @perm1 = mock_permissions(false, false)
      @perm2 = mock_permissions(false, false)
      @global_perm = mock_permissions(false, true)

      @perms = [@public_perm, @perm1, @global_perm, @perm2]
      Redmine::AccessControl.stub!(:permissions).and_return(@perms)
      Redmine::AccessControl.stub!(:public_permissions).and_return([@public_perm])
      Redmine::AccessControl.stub!(:global_permissions).and_return([@global_perm])
    end

    it {@role.setable_permissions.should eql([@perm1, @perm2])}
  end
end