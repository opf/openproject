require 'spec_helper'

describe UsersController do
  describe "routing" do
    describe "users" do
      it { get('/users/1/deletion_info').should route_to(:controller => 'users',
                                                         :action => 'deletion_info',
                                                         :id => '1') }

      it { delete('/users/1').should route_to(:controller => 'users',
                                              :action => 'destroy',
                                              :id => '1') }
    end

    describe "my" do
      let(:user) { FactoryGirl.create(:user) }

      before do
        User.stub!(:current).and_return(user)
      end

      it { get('/my/deletion_info').should route_to(:controller => 'users',
                                                    :action => 'deletion_info') }
    end
  end
end
