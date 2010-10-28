require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe RolesController do

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

  before (:each) do
    @controller.stub!(:require_admin).and_return(true)
    disable_flash_sweep
  end

  shared_examples_for "index" do
    it {response.should be_success}
    it {assigns(:roles).should eql(@roles)}
    it {assigns(:role_pages).should be_a ActionController::Pagination::Paginator}
    it {response.should render_template "roles/index.erb"}
  end

  shared_examples_for "member assigns" do
    it {assigns(:member_permissions).should eql @member_role.setable_permissions}
    it {assigns(:member_roles).should eql @roles}
    it {assigns(:member_role).should eql @member_role}
  end

  shared_examples_for "global assigns" do
    it {assigns(:global_permissions).should eql @global_role.setable_permissions}
    it {assigns(:global_roles).should eql @global_roles}
    it {assigns(:global_role).should eql @global_role}
  end

  shared_examples_for "successful create" do
    it {response.should be_redirect}
    it {response.should redirect_to "/roles"}
    it {flash[:notice].should eql I18n.t(:notice_successful_create)}
  end

  shared_examples_for "failed create" do
    it {response.should be_success}
    it {response.should render_template "create"}
  end

  describe "WITH get" do
    describe :index do
      before (:each) do
        mock_role_find
      end

      describe "html" do
        before {get "index"}

        it_should_behave_like "index"

      end

      describe "xhr" do
        before {xhr :get, "index"}

        it_should_behave_like "index"
      end
    end

    describe :new do
      before (:each) do
        @member_role = mocks_for_creating Role
        @global_role = mocks_for_creating GlobalRole
        @non_member_role = mock_model Role
        mock_permissions_on @non_member_role
        Role.stub!(:non_member).and_return(@non_member_role)

        mock_role_find
        get "new"
      end

      it {response.should be_success}
      it {response.should render_template "roles/new.erb"}
      it_should_behave_like "member assigns"
      it_should_behave_like "global assigns"
    end
  end

  describe "WITH post" do
    before(:each) do
      @member_role = mocks_for_creating Role
      @global_role = mocks_for_creating GlobalRole
      mock_role_find
      Role.stub!(:find).with("1").and_return(@member_role)
      GlobalRole.stub!(:find).with("1").and_return(@global_role)
    end

    describe "VERB", :create do

      describe "WITH member_role params" do
        before (:each) do
          @params = {"role"=>{"name"=>"role",
                            "permissions"=>["perm1", "perm2", "perm3"],
                            "assignable"=>"1"}}
        end

        describe "RESULT" do
          describe "success" do
            before(:each) do
              Role.should_receive(:new).with(@params["role"]).and_return(@member_role)
              @member_role.stub!(:save).and_return(true)
            end

            describe "html" do
              before (:each) do
                post "create", @params
              end

              it_should_behave_like "successful create"
              it_should_behave_like "member assigns" #because it is defined like this in core
            end
          end

          describe "failure" do
            before(:each) do
              Role.should_receive(:new).with(@params["role"]).and_return(@member_role)
              @member_role.stub!(:save).and_return(false)
            end

            describe "html" do
              before {post "create", @params}

              it_should_behave_like "failed create"
              it_should_behave_like "member assigns"
              it_should_behave_like "global assigns"
            end
          end
        end
      end

      describe "WITH global_role params" do
        before (:each) do
          @params = {"role"=>{"name"=>"role",
                              "permissions"=>["perm1", "perm2", "perm3"]
                              },
                      "global_role" => "1"}
        end

        describe "success" do
          before(:each) do
            GlobalRole.should_receive(:new).with(@params["role"]).and_return(@global_role)
            @global_role.stub!(:save).and_return(true)
          end

          describe "html" do
            before {post "create", @params}

            it_should_behave_like "successful create"
          end
        end

        describe "failure" do
          before(:each) do
            GlobalRole.should_receive(:new).with(@params["role"]).and_return(@global_role)
            @global_role.stub!(:save).and_return(false)
          end

          describe "html" do
            before {post "create", @params}

            it_should_behave_like "failed create"
            it_should_behave_like "global assigns"
            it_should_behave_like "member assigns"
          end
        end
      end
    end

    describe "VERB", :destroy do
      describe "WITH member_role params" do
        before {@params = {"class" => "Role", "id" => "1"}}

        describe "RESULTS" do
          describe "success" do
            before (:each) do
              @member_role.should_receive(:destroy)
              post "destroy", @params
            end

            it {response.should be_redirect}
            it {response.should redirect_to "/roles"}
          end
        end
      end

      describe "WITH global_role params" do
        before {@params = {"class" => "GlobalRole", "id" => "1"}}

        describe "RESULTS" do
          describe "success" do
            before (:each) do
              @global_role.should_receive(:destroy)
              post "destroy", @params
            end

            it {response.should be_redirect}
            it {response.should redirect_to "/roles"}
          end
        end
      end
    end
  end
end