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
require 'work_package'

describe ::OAuth::GrantsController, type: :controller do
  let(:user) { FactoryBot.build_stubbed :user }
  let(:application_stub) { instance_double(::Doorkeeper::Application, name: 'Foo', id: 1) }

  before do
    login_as user
  end

  describe '#revoke_application' do
    context 'when not found' do
      it 'renders 404' do
        post :revoke_application, params: { application_id: 1234 }
        expect(flash[:notice]).to be_nil
        expect(response.response_code).to eq 404
      end
    end

    context 'when found' do
      before do
        allow(controller)
          .to receive(:find_application)
          .and_return(application_stub)
      end

      it do
        post :revoke_application, params: { application_id: 1 }
        expect(flash[:notice]).to include 'Foo'
        expect(response).to redirect_to controller: '/my', action: :access_token
      end
    end
  end
end
