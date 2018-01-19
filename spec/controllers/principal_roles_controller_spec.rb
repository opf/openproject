#-- copyright
# OpenProject Global Roles Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe PrincipalRolesController, type: :controller do
  before(:each) do
    allow(@controller).to receive(:require_admin).and_return(true)
    allow(@controller).to receive(:check_if_login_required).and_return(true)
    allow(@controller).to receive(:set_localization).and_return(true)

    @principal_role = mock_model PrincipalRole

    if privacy_plugin_loaded?
      allow(@principal_role).to receive(:privacy_unnecessary=)
      allow(@principal_role).to receive(:valid?).and_return(true)
      allow(@principal_role).to receive(:privacy_statement_necessary?).and_return(false)
    end

    allow(@principal_role).to receive(:id).and_return(23)
    allow(PrincipalRole).to receive(:find).and_return @principal_role
    disable_flash_sweep
    disable_log_requesting_user
  end

  describe '#post' do
    before :each do
      @params = { 'principal_role' => { 'principal_id' => '3', 'role_ids' => ['7'] } }
    end

    unless privacy_plugin_loaded? # tests than are defined in privacy_plugin

      describe '#create' do
        before :each do
        end

        describe 'SUCCESS' do
          before :each do
            @global_role = mock_model(GlobalRole)
            allow(@global_role).to receive(:id).and_return(42)
            ##
            # Note this test uses doubles which may break depending on the loaded plugins.
            # Specifically extra stubs have been added for these tests to work with the
            # openproject-impermanent_memberships plugin which would be otherwise unexpected.
            # Those stubs are marked with the comment "only necessary with impermanent-memberships".
            #
            # If this problem occurs again with another plugin (or the same, really) this should be fixed for good
            # by using FactoryGirl to create actual model instances.
            # I'm only patching this up right now because I don't want to spend any more time on it and
            # the added methods are orthogonal to the test, also additional, unused stubs won't break things
            # as opposed to missing ones.
            #
            # And yet: @TODO Don't use doubles but FactoryGirl.
            allow(@global_role).to receive(:id).and_return(42)
            allow(@global_role).to receive(:permanent?).and_return(false) # only necessary with impermanent-memberships
            allow(Role).to receive(:find).and_return([@global_role])
            allow(PrincipalRole).to receive(:new).and_return(@principal_role)
            @user = mock_model User
            allow(@user).to receive(:valid?).and_return(true)
            allow(@user).to receive(:logged?).and_return(true)
            allow(@user).to receive(:global_roles).and_return([]) # only necessary with impermanent-memberships
            allow(Principal).to receive(:find).and_return(@user)
            allow(@principal_role).to receive(:role=)
            allow(@principal_role).to receive(:role).and_return(@global_role)
            allow(@principal_role).to receive(:principal_id=)
            allow(@principal_role).to receive(:save)
            allow(@principal_role).to receive(:role_id).and_return(@global_role.id)
            allow(@principal_role).to receive(:valid?).and_return(true)
          end

          describe 'js' do
            before :each do
              # post :create, { "format" => "js", "principal_role"=>{"principal_id"=>"3", "role_ids"=>["7"]}}
              post :create, params: @params, xhr: true
            end

            it { expect(response).to be_success }
            it { expect(response).to render_template 'create' }
          end
        end
      end
    end
  end

  describe '#put' do
    before :each do
      @params = { 'principal_role' => { 'id' => '6', 'role_id' => '5' } }
    end

    describe '#update' do
      before(:each) do
        allow(@principal_role).to receive(:update_attributes)
      end

      describe 'SUCCESS' do
        describe 'js' do
          before :each do
            allow(@principal_role).to receive(:valid?).and_return(true)

            put :update, params: @params.merge(id: @principal_role.id), xhr: true
          end

          it { expect(response).to be_success }
          it { expect(response).to render_template 'principal_roles/update' }
        end
      end

      describe 'FAILURE' do
        describe 'js' do
          before :each do
            allow(@principal_role).to receive(:valid?).and_return(false)
            put :update, params: @params.merge(id: @principal_role.id), xhr: true
          end

          it { expect(response).to be_success }
          it { expect(response).to render_template 'principal_roles/update' }
        end
      end
    end
  end

  describe '#delete' do
    before :each do
      allow(@principal_role).to receive(:principal_id).and_return(1)
      @user = mock_model User
      allow(@user).to receive(:logged?).and_return(true)
      # only necessary with impermanent-memberships
      allow(@user).to receive(:global_roles).and_return([])
      allow(Principal).to receive(:find).and_return(@user)
      allow(@principal_role).to receive(:destroy)

      # only necessary with impermanent-memberships
      allow(@principal_role).to receive(:role).and_return(Struct.new(:id, :permanent?).new(42, false))
      @params = { 'id' => '1' }
    end

    describe '#destroy' do
      describe 'SUCCESS' do
        describe 'js' do
          before :each do
            delete :destroy, params: @params, xhr: true
          end

          it { expect(response).to be_success }
          it { expect(response).to render_template 'destroy' }
        end
      end
    end
  end
end
