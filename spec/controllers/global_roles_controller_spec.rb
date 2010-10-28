require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")


describe GlobalRolesController do
  before (:each) do
    @role = mock_model GlobalRole
    @giveable_permissions = Redmine::AccessControl.permissions
    GlobalRole.stub!(:new).and_return(@role)
  end

  shared_examples_for "successful standard assigns" do
    it {response.should be_success}
    it_should_behave_like "standard assigns"
  end

  shared_examples_for "standard assigns" do
    it {assigns(:role).should eql(@role)}
    it {assigns(:giveable_permissions).should eql(@giveable_permissions)}
  end

  describe "get" do
    describe :new do
      before (:each) do
        get "new"
      end

      it_should_behave_like "successful standard assigns"
    end

    describe "display" do
      describe "all" do
        before {GlobalRole.should_receive(:all).and_return([@role])}
        describe :index do
          before(:each) do
            get "index", @params
          end

          it {response.should be_success}
          it {assigns(:roles).should eql([@role])}
        end
      end

      describe "one" do
        before (:each) do
          @params = {:id => "1"}
          GlobalRole.should_receive(:find).with(@params[:id]).and_return(@role)
        end

        describe :edit do
          before (:each) do
            get "edit", @params
          end

          it_should_behave_like "successful standard assigns"
        end

        describe :show do
          before (:each) do
            get "show", @params
          end

          it_should_behave_like "successful standard assigns"
        end
      end
    end
  end

  describe "post" do

    describe "modify" do
      before (:each) do
        @params = {"role" => {"id" => "1", "name" => "name",  "permissions_ids" => [1,2,3]}}
        @role.should_receive(:save).and_return(true)
      end

      describe :create do
        before (:each) do
          GlobalRole.should_receive(:new).with(@params["role"]).and_return(@role)
          post "create", @params
        end

        it_should_behave_like "successful standard assigns"
      end

      before {@params = {"role" => {"id" => "1", "name" => "name",  "permissions_ids" => [1,2,3]}}}

      describe :update do
        before(:each) do
          GlobalRole.should_receive(:find).with(@params["role"]["id"]).and_return(@role)
          @role.should_receive(:attributes=).with(@params["role"])
          post "update", @params
        end

        it_should_behave_like "successful standard assigns"
      end
    end

    describe :destroy do
      before (:each) do
        @params = {"id" => "1"}
        GlobalRole.should_receive(:find).with(@params["id"]).and_return(@role)
        @role.should_receive(:destroy)
        post "destroy", @params
      end

      it {response.should be_success}
    end
  end
end