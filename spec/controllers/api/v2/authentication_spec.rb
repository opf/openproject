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

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::V2::AuthenticationController, type: :controller do
  before { allow(Setting).to receive(:rest_api_enabled?).and_return true }

  describe 'index.xml' do
    def fetch
      get 'index', format: 'xml'
    end

    it_should_behave_like 'a controller action with require_login'

    describe 'REST API disabled' do
      before do

        allow(Setting).to receive(:rest_api_enabled?).and_return false

        fetch
      end

      it { expect(response.status).to eq(403) }
    end

    describe 'authorization data' do
      let(:user) { FactoryGirl.create(:user) }

      before do
        allow(User).to receive(:current).and_return(user)

        fetch
      end

      subject { assigns(:authorization) }

      it { expect(subject).not_to be_nil }

      it { expect(subject.authorized).to be_truthy }

      it { expect(subject.authenticated_user_id).to eq(user.id) }
    end
  end

  describe 'session' do
    let(:api_key) { user.api_key }
    let(:user) { FactoryGirl.create(:admin) }
    let(:ttl) { 42 }

    before do
      allow(Setting).to receive(:login_required?).and_return true
      allow(Setting).to receive(:rest_api_enabled?).and_return true
      allow(Setting).to receive(:session_ttl_enabled?).and_return true
      allow(Setting).to receive(:session_ttl).and_return ttl
    end

    after do
      User.current = nil
    end

    ##
    # Sessions for API requests should never expire.
    # Actually, there shouldn't be any to begin with, but we can't change that for now.
    it 'should not expire' do
      session[:updated_at] = Time.now

      get :index, format: 'xml', key: api_key
      expect(response.status).to eq(200)

      Timecop.travel(Time.now + (ttl + 1).minutes) do
        # Now another request after a normal session would be expired
        get :index, format: 'xml', key: api_key
        expect(response.status).to eq(200)
      end
    end
  end
end
