#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe ::Sessions::SqlBypass do
  subject { build(:user_session, user: user) }

  shared_examples 'augments the user_id attribute' do
    it do
      subject.save
      expect(subject.data['user_id']).to eq(user_id)
    end
  end

  describe 'when user_id is present' do
    let(:user) { build_stubbed(:user) }
    let(:user_id) { user.id }
    it_behaves_like 'augments the user_id attribute'
  end

  describe 'when user_id is nil' do
    let(:user) { nil }
    let(:user_id) { nil }
    it_behaves_like 'augments the user_id attribute'
  end

  describe 'delete other sessions on destroy' do
    let(:user) { build_stubbed(:user) }
    let!(:sessions) { create_list(:user_session, 2, user: user) }

    context 'when config is enabled',
            with_config: { drop_old_sessions_on_logout: true } do
      it 'destroys both sessions' do
        expect(::Sessions::UserSession.for_user(user).count).to eq(2)
        sessions.first.destroy

        expect(::Sessions::UserSession.count).to eq(0)
      end
    end

    context 'when config is disabled',
            with_config: { drop_old_sessions_on_logout: false } do
      it 'destroys only the one session' do
        expect(::Sessions::UserSession.for_user(user).count).to eq(2)
        sessions.first.destroy

        expect(::Sessions::UserSession.count).to eq(1)
        expect(::Sessions::UserSession.first.session_id).to eq(sessions[1].session_id)
      end
    end
  end
end
