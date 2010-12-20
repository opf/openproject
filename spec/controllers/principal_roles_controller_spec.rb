require File.dirname(__FILE__) + '/../spec_helper'

describe PrincipalRolesController do
  before(:each) do
    @controller.stub!(:require_admin).and_return(true)
    @principal_role = mock_model PrincipalRole
    disable_flash_sweep
  end

  describe :post do
    before :each do
      @params = {"principal_role"=>{"principal_id"=>"3", "role_ids"=>["7"]}}
    end

    describe :create do
      before :each do

      end

      describe "SUCCESS" do
        before :each do
          Role.stub!(:find).and_return([mock_model(GlobalRole)])
          PrincipalRole.stub!(:new).and_return(@principal_role)
          @principal_role.stub!(:role=)
          @principal_role.stub!(:save)
        end

        describe "js" do
          before :each do
            response_should_render :insert_html,
                                   :top, 'table_principal_roles_body',
                                   :partial => "principal_roles/show_table_row",
                                   :locals => {:principal_role => anything()}
            xhr :post, :create, @params
          end

          it { response.should be_success }
        end
      end
    end
  end

  describe :delete do
    before :each do

      PrincipalRole.stub!(:find).and_return @principal_role
      @principal_role.stub!(:destroy)
      @params = {"id" => "1"}
    end

    describe :destroy do
      before :each do

      end

      describe "SUCCESS" do
        before :each do
          response_should_render :remove, "principal_role_1"
        end

        describe "js" do
          before :each do
            xhr :delete, :destroy, @params
          end

          it { response.should be_success }


        end
      end
    end


  end
end