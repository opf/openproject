#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
require 'rack/test'

describe 'API v3 User avatar resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:user) { FactoryBot.create(:admin) }

  subject(:response) { last_response }

  before do
    login_as user
  end

  describe '/avatar', with_settings: { protocol: 'http' } do
    before do
      allow(Setting)
        .to receive(:plugin_openproject_avatars)
        .and_return(enable_gravatars: gravatars, enable_local_avatars: local_avatars)

      get api_v3_paths.user(user.id) + "/avatar"
    end

    context 'with neither enabled' do
      let(:gravatars) { false }
      let(:local_avatars) { false }

      it 'renders a 404' do
        expect(response.status).to eq 404
      end
    end

    context 'when gravatar enabled' do
      let(:gravatars) { true }
      let(:local_avatars) { false }

      it 'redirects to gravatar' do
        expect(response.status).to eq 302
        expect(response.location).to match /gravatar\.com/
      end
    end

    context 'with local avatar' do
      let(:gravatars) { true }
      let(:local_avatars) { true }

      let(:user) do
        u = FactoryBot.create :admin
        u.attachments = [FactoryBot.build(:avatar_attachment, author: u)]
        u
      end

      it 'serves the attachment file' do
        expect(response.status).to eq 200
      end
    end
  end
end
