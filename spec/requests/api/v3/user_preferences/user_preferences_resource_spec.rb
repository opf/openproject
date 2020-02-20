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
require 'rack/test'

describe 'API v3 UserPreferences resource', type: :request do
  include Rack::Test::Methods
  include ::API::V3::Utilities::PathHelper

  let(:user) { FactoryBot.create(:user) }
  let(:preference) { FactoryBot.create(:user_preference, user: user) }
  let(:preference_path) { api_v3_paths.my_preferences }
  subject(:response) { last_response }

  before do
    allow(User).to receive(:current).and_return user
    allow(User).to receive(:preference).and_return preference
  end

  describe '#GET' do
    before do
      get preference_path
    end

    context 'when not logged in' do
      let(:user) { User.anonymous }

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with a UserPreferences representer' do
        expect(subject.body).to be_json_eql('UserPreferences'.to_json).at_path('_type')
      end
    end

    context 'when logged in' do
      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with a UserPreferences representer' do
        expect(subject.body).to be_json_eql('UserPreferences'.to_json).at_path('_type')
      end
    end
  end

  describe '#PATCH' do
    before do
      patch preference_path, params.to_json, 'CONTENT_TYPE' => 'application/json'
      preference.reload
    end

    context 'when not logged in' do
      let(:user) { User.anonymous }
      let(:params) do
        { whatever: true }
      end
      it 'should respond with 401' do
        expect(subject.status).to eq(401)
      end
    end

    describe 'timezone' do
      context 'with invalid timezone' do
        let(:params) do
          { timeZone: 'Europe/Awesomeland' }
        end

        it_behaves_like 'constraint violation' do
          let(:message) { 'Time zone is not set to one of the allowed values.' }
        end
      end

      context 'with full time zone' do
        let(:params) do
          { timeZone: 'Europe/Paris' }
        end
        it 'should respond with a UserPreferences representer' do
          expect(subject.body).to be_json_eql('Europe/Paris'.to_json).at_path('timeZone')
          expect(preference.time_zone).to eq('Europe/Paris')
        end
      end

      context 'with short time zone' do
        let(:params) do
          { timeZone: 'Hawaii' }
        end

        it 'should respond with a UserPreferences representer' do
          expect(subject.body).to be_json_eql('Pacific/Honolulu'.to_json).at_path('timeZone')
          expect(preference.time_zone).to eq('Hawaii')
          expect(preference.canonical_time_zone).to eq('Pacific/Honolulu')
        end
      end
    end
  end
end
