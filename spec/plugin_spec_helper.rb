module GlobalRoles
  module PluginSpecHelper
    def mocks_for_member_roles
      @role = mock_model Role
      Role.stub!(:new).and_return(@role)

      mock_permissions_on @role

      mock_role_find

      @non_mem = mock_model Role
      @non_mem.stub!(:permissions).and_return(@non_mem_perm)
      Role.stub!(:non_member).and_return(@non_mem)
      @non_mem_perm = [:nm_perm1, :nm_perm2]
    end

    def mocks_for_global_roles
      @role = mock_model GlobalRole
      GlobalRole.stub!(:new).and_return(@role)
      mock_permissions_on @role
    end

    def mock_permissions_on role
      permissions = [:perm1, :perm2, :perm3]
      role.stub!(:setable_permissions).and_return(permissions)
      role.stub!(:permissions).and_return(permissions << :perm4)
    end

    def mock_role_find
      mock_member_role_find
      mock_global_role_find
    end

    def mock_member_role_find
      @role1 = mock_model Role
      @role2 = mock_model Role
      @global_role1 = mock_model GlobalRole
      @global_role2 = mock_model GlobalRole
      @roles = [@role1, @global_role2, @role2, @global_role1]
      Role.stub!(:find).and_return(@roles)
      Role.stub!(:all).and_return(@roles)
    end

    def mock_global_role_find
      @global_role1 = mock_model GlobalRole
      @global_role2 = mock_model GlobalRole
      @global_roles = [@global_role1, @global_role2]
      GlobalRole.stub!(:find).and_return(@global_roles)
      GlobalRole.stub!(:all).and_return(@global_roles)
    end

    def mocks_for_creating role_class
      role = mock_model role_class
      role_class.stub!(:new).and_return role
      mock_permissions_on role
      role
    end

    def disable_flash_sweep
     @controller.instance_eval{flash.stub!(:sweep)}
    end

    def response_should_render method, *params
      page = mock("page")
      controller.should_receive(:render).with(:update).and_yield(page)

      page.should_receive(method).with(*params)
    end
  end
end