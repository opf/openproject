require 'spec_helper'

describe "layouts/base" do
  include Redmine::MenuManager::MenuHelper
  helper Redmine::MenuManager::MenuHelper
  let!(:user) { FactoryGirl.create :user }
  let!(:anonymous) { FactoryGirl.create(:anonymous) }

  before do
    view.stub(:current_menu_item).and_return("overview")
    view.stub(:default_breadcrumb)
    controller.stub(:default_search_scope)
  end

  describe "projects menu visibility" do
    context "when the user is not logged in" do
      before do
        User.stub(:current).and_return anonymous
        view.stub(:current_user).and_return anonymous
        render
      end

      it "the projects menu should not be displayed" do
        expect(response).to_not have_text("Projects")
      end
    end

    context "when the user is logged in" do
      before do
        User.stub(:current).and_return user
        view.stub(:current_user).and_return user
        render
      end

      it "the projects menu should be displayed" do
        expect(response).to have_text("Projects")
      end

      it 'the sign-in menu should be displayed' do
        expect(response).to have_text('Sign in')
      end
    end
  end
end
