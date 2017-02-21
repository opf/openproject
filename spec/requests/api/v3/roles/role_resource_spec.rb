#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 Role resource' do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) { FactoryGirl.create(:user) }
  let(:role) { FactoryGirl.create(:role) }

  before do
    # Avoid having a builtin role left over from another spec
    Role.delete_all

    allow(User).to receive(:current).and_return current_user
  end

  describe '#get /roles' do
    let(:get_path) { api_v3_paths.roles }
    let(:response) { last_response }

    before do
      role

      get get_path
    end

    it 'succeeds' do
      expect(last_response.status)
        .to eql(200)
    end

    it_behaves_like 'API V3 collection response', 1, 1, 'Role'
  end

  describe '#get /roles/:id' do
    let(:get_path) { api_v3_paths.role(role.id) }
    let(:response) { last_response }

    before do
      role

      get get_path
    end

    it 'succeeds' do
      expect(last_response.status)
        .to eql(200)
    end

    it 'returns the role' do
      expect(last_response.body)
        .to be_json_eql(get_path.to_json)
        .at_path('_links/self/href')
    end

    context 'for non existing role id' do
      let(:get_path) { api_v3_paths.role(0) }

      it_behaves_like 'not found'
    end
  end
end
