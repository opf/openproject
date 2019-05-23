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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RolesController, type: :controller do
  before do
    allow(@controller).to receive(:check_if_login_required)
    expect(@controller).to receive(:require_admin)
    disable_flash_sweep
  end

  after do
    User.current = nil
  end

  shared_examples_for 'index' do
    it {expect(response).to be_successful}
    it {expect(assigns(:roles)).to eql(@roles)}
    it {expect(response).to render_template 'roles/index'}
  end

  shared_examples_for 'global assigns' do
    it {expect(assigns(:global_roles)).to eql @global_roles}
    it {expect(assigns(:global_role)).to eql @global_role}
  end

  shared_examples_for 'successful create' do
    it {expect(response).to be_redirect}
    it {expect(response).to redirect_to '/admin/roles'}
    it {expect(flash[:notice]).to eql I18n.t(:notice_successful_create)}
  end

  shared_examples_for 'failed create' do
    it {expect(response).to be_successful}
    it {expect(response).to render_template 'new'}
  end

  describe 'WITH get' do
    describe 'VERB', :index do
      before do
        mock_role_find
      end

      describe 'html' do
        before {get 'index'}

        it_should_behave_like 'index'
      end

      describe 'xhr' do
        before {get :index, xhr: true}

        it_should_behave_like 'index'
      end
    end

    describe 'VERB', :new do
      before do
        @member_role = mocks_for_creating Role
        allow(::Redmine::AccessControl).to receive(:sorted_modules).and_return(%w(Foo))
        allow(GlobalRole).to receive(:setable_permissions).and_return(doubled_permissions)
        @non_member_role = mock_model Role
        mock_permissions_on @non_member_role
        allow(Role).to receive(:non_member).and_return(@non_member_role)

        mock_role_find
        get 'new'
      end

      it 'renders new' do
        expect(response).to be_successful
        expect(response).to render_template 'roles/new'
        expect(assigns(:permissions))
          .to eql([['Foo', @member_role.setable_permissions]])
        expect(assigns(:roles)).to eql @roles
        expect(assigns(:role)).to eql @member_role
      end
    end

    describe 'VERB', :edit do
      before(:each) do
        @member_role = mocks_for_creating Role
        @global_role = mocks_for_creating GlobalRole
        mock_role_find
      end

      describe 'WITH member_role id' do
        before do
          @params = {'id' => '1'}
          allow(Role).to receive(:find).and_return(@member_role)
        end

        describe 'RESULT' do
          describe 'success' do
            describe 'html' do
              before do
                allow(::Redmine::AccessControl).to receive(:sorted_modules).and_return(%w(Foo))
                get :edit, params: @params
              end


              it do
                expect(response).to be_successful
                expect(response).to render_template 'roles/edit'
                expect(assigns(:role)).to eql @member_role
                expect(assigns(:permissions))
                  .to eql([['Foo', @member_role.setable_permissions]])
              end
            end
          end
        end
      end
    end
  end

  describe 'WITH post' do
    before(:each) do
      @member_role = mocks_for_creating Role
      @global_role = mocks_for_creating GlobalRole
      mock_role_find
      allow(Role).to receive(:find).with('1').and_return(@member_role)
      allow(Role).to receive(:find).with('2').and_return(@global_role)
    end

    describe 'VERB', :create do
      describe 'WITH member_role params' do
        before do
          @params = {'role' => {'name' => 'role',
                                'permissions' => %w(perm1 perm2 perm3),
                                'assignable' => '1'}}
        end

        describe 'RESULT' do
          describe 'success' do
            before(:each) do
              expect(Role)
                .to receive(:new)
                      .with(ActionController::Parameters.new(@params['role']).permit!)
                      .and_return(@member_role)
              allow(@member_role).to receive(:save).and_return(true)
              allow(@member_role).to receive(:errors).and_return([])
            end

            describe 'html' do
              before do
                post 'create', params: @params
              end

              it_should_behave_like 'successful create'
              it {expect(assigns(:role)).to eql @member_role}
            end
          end

          describe 'failure' do
            before(:each) do
              expect(Role)
                .to receive(:new)
                      .with(ActionController::Parameters.new(@params['role']).permit!)
                      .and_return(@member_role)
              allow(@member_role).to receive(:save).and_return(false)
              allow(@member_role).to receive(:errors).and_return(['something is wrong'])
            end

            describe 'html' do
              before {post 'create', params: @params}

              it_should_behave_like 'failed create'
              it {expect(assigns(:role)).to eql @member_role}
              it {expect(assigns(:roles)).to eql Role.all}
            end
          end
        end
      end

      describe 'WITH global_role params' do
        before do
          @params = {'role' => {'name' => 'role',
                                'permissions' => %w(perm1 perm2 perm3)
          },
                     'global_role' => '1'}
        end

        describe 'RESULTS' do
          describe 'success' do
            before(:each) do
              expect(GlobalRole)
                .to receive(:new)
                      .with(ActionController::Parameters.new(@params['role']).permit!)
                      .and_return(@global_role)
              allow(@global_role).to receive(:save).and_return(true)
            end

            describe 'html' do
              before {post 'create', params: @params}

              it_should_behave_like 'successful create'
            end
          end

          describe 'failure' do
            before(:each) do
              expect(GlobalRole)
                .to receive(:new)
                      .with(ActionController::Parameters.new(@params['role']).permit!)
                      .and_return(@global_role)
              allow(@global_role).to receive(:save).and_return(false)
            end

            describe 'html' do
              before {post 'create', params: @params}

              it_should_behave_like 'failed create'
              it {expect(assigns(:role)).to eql @global_role}
              it {expect(assigns(:roles)).to eql Role.all}
            end
          end
        end
      end
    end

    describe 'VERB', :destroy do
      shared_examples_for 'destroy results' do
        describe 'success' do
          before do
            expect(@role).to receive(:destroy)
            post 'destroy', params: @params
          end

          it {expect(response).to be_redirect}
          it {expect(response).to redirect_to '/admin/roles'}
        end
      end

      describe 'WITH member_role params' do
        before do
          @params = {'class' => 'Role', 'id' => '1'}
          @role = @member_role
        end

        describe 'RESULTS' do
          it_should_behave_like 'destroy results'
        end
      end

      describe 'WITH global_role params' do
        before do
          @params = {'class' => 'Role', 'id' => '2'}
          @role = @global_role
        end

        describe 'RESULTS' do
          it_should_behave_like 'destroy results'
        end
      end
    end

    describe 'VERB', :update do
      shared_examples_for 'update results' do
        describe 'success' do
          describe 'html' do
            before do
              expect(@role)
                .to receive(:update_attributes)
                      .with(ActionController::Parameters.new(@params['role']).permit!)
                      .and_return(true)
              allow(@role).to receive(:errors).and_return([])
              post :update, params: @params
            end

            it {expect(response).to be_redirect}
            it {expect(response).to redirect_to '/admin/roles'}
            it {expect(flash[:notice]).to eql I18n.t(:notice_successful_update)}
          end
        end

        describe 'failure' do
          describe 'html' do
            before(:each) do
              expect(@role)
                .to receive(:update_attributes)
                      .with(ActionController::Parameters.new(@params['role']).permit!)
                      .and_return(false)
              allow(@role).to receive(:errors).and_return(['something is wrong'])
              post :update, params: @params
            end

            it {expect(response).to render_template 'roles/edit'}
          end
        end
      end

      describe 'WITH member_role params' do
        before do
          @params = {'role' => {'permissions' => %w(permA permB),
                                'name' => 'schmu'},
                     'id' => '1'}
          @role = @member_role
        end

        describe 'RESULT' do
          it_should_behave_like 'update results'
        end
      end

      describe 'WITH global_role params' do
        before do
          @params = {'role' => {'permissions' => %w(permA permB),
                                'name' => 'schmu'},
                     'id' => '2'}
          @role = @global_role
        end

        describe 'RESULT' do
          it_should_behave_like 'update results'
        end
      end
    end
  end
end
