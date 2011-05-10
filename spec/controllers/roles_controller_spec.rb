require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe RolesController do
  before (:each) do
    @controller.stub!(:require_admin).and_return(true)
    disable_flash_sweep
  end

  shared_examples_for "index" do
    it {response.should be_success}
    it {assigns(:roles).should eql(@roles)}
    it {assigns(:role_pages).should be_a ActionController::Pagination::Paginator}
    it {response.should render_template "roles/index"}
  end

  shared_examples_for "global assigns" do
    it {assigns(:global_permissions).should eql @global_role.setable_permissions}
    it {assigns(:global_roles).should eql @global_roles}
    it {assigns(:global_role).should eql @global_role}
  end

  shared_examples_for "permission assigns" do
    it {assigns(:member_permissions).should eql @member_role.setable_permissions}
    it {assigns(:global_permissions).should eql GlobalRole.setable_permissions}
  end

  shared_examples_for "successful create" do
    it {response.should be_redirect}
    it {response.should redirect_to "/roles"}
    it {flash[:notice].should eql I18n.t(:notice_successful_create)}
  end

  shared_examples_for "failed create" do
    it {response.should be_success}
    it {response.should render_template "new"}
  end



  describe "WITH get" do
    describe "VERB", :index do
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

    describe "VERB", :new do
      before (:each) do
        @member_role = mocks_for_creating Role
        GlobalRole.stub!(:setable_permissions).and_return([:perm1, :perm2, :perm3])
        @non_member_role = mock_model Role
        mock_permissions_on @non_member_role
        Role.stub!(:non_member).and_return(@non_member_role)

        mock_role_find
        get "new"
      end

      it {response.should be_success}
      it {response.should render_template "roles/new"}
      it {assigns(:member_permissions).should eql @member_role.setable_permissions}
      it {assigns(:roles).should eql @roles}
      it {assigns(:role).should eql @member_role}
      it {assigns(:global_permissions).should eql GlobalRole.setable_permissions}
    end

    describe "VERB", :edit do
      before(:each) do
        @member_role = mocks_for_creating Role
        @global_role = mocks_for_creating GlobalRole
        mock_role_find
      end

      describe "WITH member_role id" do
        before (:each) do
          @params = {"id" => "1"}
          Role.stub!(:find).and_return(@member_role)
        end

        describe "RESULT" do
          describe "success" do
            describe "html" do
              before {get :edit, @params}

              it {response.should be_success}
              it {response.should render_template "roles/edit"}
              it {assigns(:role).should eql @member_role}
              it {assigns(:permissions).should eql @member_role.setable_permissions}
            end
          end
        end
      end
    end
  end

  describe "WITH post" do
    before(:each) do
      @member_role = mocks_for_creating Role
      @global_role = mocks_for_creating GlobalRole
      mock_role_find
      Role.stub!(:find).with("1").and_return(@member_role)
      Role.stub!(:find).with("2").and_return(@global_role)
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
              @member_role.stub!(:errors).and_return([])
            end

            describe "html" do
              before (:each) do
                post "create", @params
              end

              it_should_behave_like "successful create"
              it {assigns(:role).should eql @member_role}
            end
          end

          describe "failure" do
            before(:each) do
              Role.should_receive(:new).with(@params["role"]).and_return(@member_role)
              @member_role.stub!(:save).and_return(false)
              @member_role.stub!(:errors).and_return(["something is wrong"])
            end

            describe "html" do
              before {post "create", @params}

              it_should_behave_like "failed create"
              it {assigns(:role).should eql @member_role}
              it {assigns(:roles).should eql Role.all}
              it_should_behave_like "permission assigns"
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

        describe "RESULTS" do
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
              it {assigns(:role).should eql @global_role}
              it {assigns(:roles).should eql Role.all}
              it_should_behave_like "permission assigns"
            end
          end
        end
      end
    end



    describe "VERB", :destroy do
      shared_examples_for "destroy results" do
        describe "success" do
          before (:each) do
            @role.should_receive(:destroy)
            post "destroy", @params
          end

          it {response.should be_redirect}
          it {response.should redirect_to "/roles"}
        end
      end

      describe "WITH member_role params" do
        before (:each) do
          @params = {"class" => "Role", "id" => "1"}
          @role = @member_role
        end

        describe "RESULTS" do
          it_should_behave_like "destroy results"
        end
      end

      describe "WITH global_role params" do
        before (:each) do
          @params = {"class" => "Role", "id" => "2"}
          @role = @global_role
        end

        describe "RESULTS" do
          it_should_behave_like "destroy results"
        end
      end
    end


    describe "VERB", :update do
      shared_examples_for "update results" do
        describe "success" do
          describe "html" do
            before (:each) do
              @role.should_receive(:update_attributes).with(@params["role"]).and_return(true)
              @role.stub!(:errors).and_return([])
              post :update, @params
            end

            it {response.should be_redirect}
            it {response.should redirect_to "/roles"}
            it {flash[:notice].should eql I18n.t(:notice_successful_update)}
          end
        end

        describe "failure" do
          describe "html" do
            before(:each) do
              @role.should_receive(:update_attributes).with(@params["role"]).and_return(false)
              @role.stub!(:errors).and_return(["something is wrong"])
              post :update, @params
            end

            it { response.should render_template "roles/edit" }
          end
        end
      end

      describe "WITH member_role params" do
        before (:each) do
          @params = {"role" => {"permissions" => ["permA", "permB"],
                                "name" => "schmu"},
                     "id" => "1"}
          @role = @member_role
        end

        describe "RESULT" do
          it_should_behave_like "update results"
        end
      end

      describe "WITH global_role params" do
        before (:each) do
          @params = {"role" => {"permissions" => ["permA", "permB"],
                                "name" => "schmu"},
                     "id" => "2"}
          @role = @global_role
        end

        describe "RESULT" do
          it_should_behave_like "update results"
        end
      end
    end
  end
end