#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

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
    end
  end

  describe 'Sign in button' do
    before do
      User.stub(:current).and_return anonymous
      view.stub(:current_user).and_return anonymous
    end

    context 'with omni_auth_direct_login disabled' do
      before do
        render
      end

      it 'shows the login drop down menu' do
        expect(response).to have_selector "div[id='nav-login-content']"
      end
    end

    context 'with omni_auth_direct_login enabled' do
      before do
        expect(Concerns::OmniauthLogin).to receive(:direct_login_provider).and_return('some_provider')
        render
      end

      it 'shows just a sign-in link, no menu' do
        expect(response).to have_selector "a[href='/login']"
        expect(response).not_to have_selector "div[id='nav-login-content']"
      end
    end
  end

  describe 'login form' do
    before do
      User.stub(:current).and_return anonymous
      view.stub(:current_user).and_return anonymous
    end

    context 'with password login enabled' do
      before do
        render
      end

      it 'shows a login form' do
        expect(response).to include 'Login'
        expect(response).to include 'Password'
      end
    end

    context 'with password login disabled' do
      before do
        OpenProject::Configuration.stub(:disable_password_login?).and_return(true)
        render
      end

      it 'shows no password login form' do
        expect(response).not_to include 'Login'
        expect(response).not_to include 'Password'
      end
    end
  end
end
