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

describe OmniAuth::FlexibleStrategy do
  class MockStrategy
    include OmniAuth::Strategy
    include OmniAuth::FlexibleStrategy

    def request_phase
      call_app!
    end
  end

  def env_for(url, opts = {})
    Rack::MockRequest.env_for(url, opts).tap do |env|
      env['rack.session'] = {}
    end
  end

  let(:app)        { ->(env) { [200, env, 'ok'] } }
  let(:middleware) { MockStrategy.new(app) }
  let(:provider_a) { { name: 'provider_a', identifier: 'a' } }
  let(:provider_b) { { name: 'provider_b', identifier: 'b' } }

  before do
    allow(OpenProject::Plugins::AuthPlugin).to receive(:providers_for).with(MockStrategy) {
      [provider_a, provider_b]
    }
  end

  describe 'request call' do
    it 'should match the registered providers' do
      [provider_a, provider_b].each do |pro|
        code, env = middleware.call env_for("http://www.example.com/auth/#{pro[:name]}")
        strategy = env['omniauth.strategy']

        # check that the correct provider has been initialised
        expect(strategy.options.identifier).to eq pro[:identifier]
      end
    end

    it 'should not match other paths' do
      code, env = middleware.call env_for('http://www.example.com/auth/other_provider')

      expect(env).not_to include 'omniauth.strategy' # no hit
    end
  end

  describe 'callback call' do
    before do
      allow_any_instance_of(MockStrategy).to receive(:callback_phase).and_return(['hit'])
    end

    it 'should match the registered providers' do
      [provider_a, provider_b].each do |pro|
        code, _ = middleware.call env_for("http://www.example.com/auth/#{pro[:name]}/callback")

        expect(code).to eq 'hit'
      end
    end

    it 'should not match other paths' do
      code, env = middleware.call env_for('http://www.example.com/auth/other_provider/callback')

      expect(code).to eq 200
      expect(env).not_to include 'omniauth.strategy' # no hit
    end
  end

  describe 'calling strategies' do
    let(:provider_with_mapping) do
      {
        name: 'provider_with_mapping',
        openproject_attribute_map: Proc.new do |auth|
          { uid: auth[:info][:myUsername], mail: auth[:extra][:raw_info][:myMail] }
        end
      }
    end
    let(:auth_hash) do
      {
        info: { myUsername: 'foo', myFullName: 'Foo Bar' },
        extra: { raw_info: { myMail: 'foo@example.com' } }
      }
    end

    before do
      middleware.providers = [provider_a, provider_with_mapping]
    end

    context 'with a mapping set' do
      it 'returns an attribute hash' do
        _, env = middleware.call env_for('http://www.example.com/auth/provider_with_mapping')

        strategy = env['omniauth.strategy']
        expect(strategy.name).to eq('provider_with_mapping')
        attribute_map = strategy.omniauth_hash_to_user_attributes(auth_hash)
        expect(attribute_map).to eq(uid: 'foo', mail: 'foo@example.com')
      end
    end

    context 'without a mapping set' do
      it 'returns an empty hash' do
        middleware.call env_for('http://www.example.com/auth/provider_a')

        attribute_map = middleware.omniauth_hash_to_user_attributes(auth_hash)
        expect(attribute_map).to eq({})
      end
    end
  end
end
