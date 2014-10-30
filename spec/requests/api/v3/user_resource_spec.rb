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
require 'rack/test'

describe 'API v3 User resource', :type => :request do
  include Rack::Test::Methods

  let(:current_user) { FactoryGirl.create(:user) }
  let(:user) { FactoryGirl.create(:user) }
  let(:model) { ::API::V3::Users::UserModel.new(user) }
  let(:representer) { ::API::V3::Users::UserRepresenter.new(model) }

  describe '#get' do
    subject(:response) { last_response }

    context 'logged in user' do
      let(:get_path) { "/api/v3/users/#{user.id}" }
      before do
        allow(User).to receive(:current).and_return current_user
        get get_path
      end

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with correct attachment' do
        expect(subject.body).to be_json_eql(user.name.to_json).at_path('name')
      end

      context 'requesting nonexistent user' do
        let(:get_path) { "/api/v3/users/9999" }

        it_behaves_like 'not found', 9999, 'User'
      end
    end

    it_behaves_like 'handling anonymous user', 'User', '/api/v3/users/%s' do
      let(:id) { user.id }
    end
  end
end
