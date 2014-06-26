require 'spec_helper'

describe "layouts/base", :type => :view do
  include Redmine::MenuManager::MenuHelper
  helper Redmine::MenuManager::MenuHelper
  let!(:user) { FactoryGirl.create :user }
  let!(:anonymous) { FactoryGirl.create(:anonymous) }

  before do
    allow(view).to receive(:current_menu_item).and_return("overview")
    allow(view).to receive(:default_breadcrumb)
    allow(controller).to receive(:default_search_scope)
  end

  describe "projects menu visibility" do
    context "when the user is not logged in" do
      before do
        allow(User).to receive(:current).and_return anonymous
        allow(view).to receive(:current_user).and_return anonymous
        render
      end

      it "the projects menu should not be displayed" do
        expect(response).to_not have_text("Projects")
      end
    end

    context "when the user is logged in" do
      before do
        allow(User).to receive(:current).and_return user
        allow(view).to receive(:current_user).and_return user
        render
      end

      it "the projects menu should be displayed" do
        expect(response).to have_text("Projects")
      end
    end
  end
end
