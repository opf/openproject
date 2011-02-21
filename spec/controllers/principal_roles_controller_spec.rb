require File.dirname(__FILE__) + '/../spec_helper'

describe PrincipalRolesController do
  before(:each) do
    @controller.stub!(:require_admin).and_return(true)
    @controller.stub!(:check_if_login_required).and_return(true)
    @principal_role = mock_model PrincipalRole
    if privacy_plugin_loaded?
      @principal_role.stub!(:privacy_unnecessary=)
      @principal_role.stub!(:valid?).and_return(true)
      @principal_role.stub!(:privacy_statement_necessary?).and_return(false)
    end

    @principal_role.stub!(:id).and_return(23)
    PrincipalRole.stub!(:find).and_return @principal_role
    disable_flash_sweep
  end

  describe :post do
    before :each do
      @params = {"principal_role"=>{"principal_id"=>"3", "role_ids"=>["7"]}}
    end

    unless privacy_plugin_loaded? #tests than are defined in privacy_plugin

      describe :create do
        before :each do

        end

        describe "SUCCESS" do
          before :each do
            @global_role = mock_model(GlobalRole)
            @global_role.stub!(:id).and_return(42)
            Role.stub!(:find).and_return([@global_role])
            PrincipalRole.stub!(:new).and_return(@principal_role)
            @principal_role.stub!(:role=)
            @principal_role.stub!(:role).and_return(@global_role)
            @principal_role.stub!(:save)
            @principal_role.stub!(:role_id).and_return(@global_role.id)
          end

          describe "js" do
            before :each do
              response_should_render :replace,
                                     "available_principal_roles",
                                     :partial => "users/available_global_roles",
                                     :locals => {:global_roles => anything(),
                                                 :user => anything()}
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
  end

  describe :put do
    before :each do
      @params = {"principal_role"=>{"id"=>"6", "role_id" => "5"}}
    end

    describe :update do
      before(:each) do
        @principal_role.stub!(:update_attributes)
      end

      describe "SUCCESS" do
        describe "js" do
          before :each do
            @principal_role.stub!(:valid?).and_return(true)

            response_should_render :replace,
                                  "principal_role-#{@principal_role.id}",
                                  :partial => "principal_roles/show_table_row",
                                  :locals => {:principal_role => anything()}

            xhr :put, :update, @params
          end

          it {response.should be_success}
        end
      end

      describe "FAILURE" do
        describe "js" do
          before :each do
            @principal_role.stub!(:valid?).and_return(false)
            response_should_render :insert_html,
                                   :top,
                                   "tab-content-global_roles",
                                   :partial => 'errors'

            xhr :put, :update, @params
          end

          it {response.should be_success}
        end
      end
    end
  end

  describe :delete do
    before :each do
      @principal_role.stub!(:principal_id).and_return(1)
      Principal.stub(:find).and_return(mock_model User)
      @principal_role.stub!(:destroy)
      @params = {"id" => "1"}
    end

    describe :destroy do
      describe "SUCCESS" do
        before :each do
          response_should_render :remove, "principal_role-#{@principal_role.id}"
          response_should_render :replace,
                                 "available_principal_roles",
                                 :partial => "users/available_global_roles",
                                 :locals => {:global_roles => anything(),
                                             :user => anything()}
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