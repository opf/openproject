#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe AdminController, type: :controller do
  let(:user) { FactoryBot.build :admin }

  before do
    allow(User).to receive(:current).and_return user
  end

  describe '#index' do
    it 'renders index' do
      get :index

      expect(response).to be_successful
      expect(response).to render_template 'index'
    end

    describe "with a plugin adding a menu item" do
      render_views

      let(:visible) { true }
      let(:plugin_name) { nil }

      before do
        show = visible
        name = plugin_name

        Redmine::Plugin.register name.to_sym do
          menu :admin_menu,
               :"#{name}_settings",
               { controller: '/settings', action: :plugin, id: :"openproject_#{name}" },
               caption: name.capitalize,
               icon: 'icon2 icon-arrow',
               if: ->(*) { show }
        end

        get :index
      end

      context "with the menu item visible" do
        let(:plugin_name) { "Apple" }
        let(:visible) { true }

        it "should show the plugin in the overview" do
          expect(response.body).to have_selector('a.menu-block', text: plugin_name.capitalize)
        end
      end

      context "with the menu item hidden" do
        let(:plugin_name) { "Orange" }
        let(:visible) { false }

        it "should not show the plugin in the overview" do
          expect(response.body).not_to have_selector('a.menu-block', text: plugin_name.capitalize)
        end
      end
    end
  end

  describe '#plugins' do
    render_views

    context 'with plugins' do
      before do
        Redmine::Plugin.register :foo do end
        Redmine::Plugin.register :bar do end
      end

      it 'renders the plugins' do
        get :plugins

        expect(response).to be_successful
        expect(response).to render_template 'plugins'

        expect(response.body).to have_selector('td span', text: 'Foo')
        expect(response.body).to have_selector('td span', text: 'Bar')
      end
    end

    context 'without plugins' do
      before do
        Redmine::Plugin.clear
      end

      it 'renders even without plugins' do
        get :plugins
        expect(response).to be_successful
        expect(response).to render_template 'plugins'
      end
    end
  end

  describe '#info' do
    it 'renders info' do
      get :info

      expect(response).to be_successful
      expect(response).to render_template 'info'
    end
  end
end
