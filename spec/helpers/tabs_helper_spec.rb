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

describe TabsHelper, type: :helper do
  include TabsHelper

  let(:given_tab) {
    { name: 'avatar',
      partial: 'avatars/users/avatar_tab',
      path: ->(params) { tab_edit_user_path(params[:user], tab: :avatar) },
      label: :label_avatar }
  }

  let(:expected_tab) {
    { name: 'avatar',
      partial: 'avatars/users/avatar_tab',
      path: '/users/2/edit/avatar',
      label: :label_avatar }
  }

  describe 'render_extensible_tabs' do
    before do
      allow_any_instance_of(TabsHelper)
        .to receive(:render_tabs)
        .with([ expected_tab ])
        .and_return [ expected_tab ]

      allow(::OpenProject::Ui::ExtensibleTabs)
        .to receive(:enabled_tabs)
        .with(:user)
        .and_return [ given_tab ]

      user = FactoryBot.build(:user, id: 2)
      @tabs = render_extensible_tabs(:user, user: user)
    end

    it "should return an evaluated path" do
      expect(response.status).to eq 200
      expect(@tabs).to eq([ expected_tab ])
    end
  end
end
