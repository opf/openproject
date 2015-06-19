#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

require File.expand_path('../../../../../spec_helper', __FILE__)

describe 'api/v2/authentication/index.api.rabl', type: :view do
  before { params[:format] = 'json' }

  shared_examples_for 'valid authentication' do
    it { expect(subject).to have_json_path('authorization') }

    it { expect(subject).to have_json_size(2).at_path('authorization') }

    it { expect(subject).to be_json_eql(content).at_path('authorization') }
  end

  describe 'authentication state' do
    before do
      assign(:authorization, Api::V2::AuthenticationController::AuthorizationData.new(true, nil))

      render
    end

    subject { response.body }

    it_behaves_like 'valid authentication' do
      let(:content) { %({"authorized": true, "authenticated_user_id":null}) }
    end
  end

  describe 'authenticated user' do
    before do
      assign(:authorization, Api::V2::AuthenticationController::AuthorizationData.new(nil, 12345))

      render
    end

    subject { response.body }

    it_behaves_like 'valid authentication' do
      let(:content) { %({"authorized":null, "authenticated_user_id": 12345}) }
    end
  end
end
