require 'spec_helper'

describe MembersController do
  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project) }
  let(:role) { FactoryGirl.create(:role) }
  let(:member) { FactoryGirl.create(:member, :project => project,
                                             :user => user,
                                             :roles => [role]) }

  before do
    User.stub!(:current).and_return(user)
  end

  describe :autocomplete_for_member do
    let(:params) { ActionController::Parameters.new({ "id" => project.identifier.to_s }) }

    describe "WHEN the user is authorized
              WHEN a project is provided" do
      before do
        role.permissions << :manage_members
        role.save!
        member

        post :autocomplete_for_member, params, :format => :xhr
      end

      it "should be success" do
        response.should be_success
      end
    end

    describe "WHEN the user is not authorized" do
      before do
        post :autocomplete_for_member, params, :format => :xhr
      end

      it "should be forbidden" do
        response.response_code.should == 403
      end
    end
  end
end
