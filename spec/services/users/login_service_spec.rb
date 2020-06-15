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

describe ::Users::LoginService, type: :model do
  let(:input_user) { FactoryBot.build_stubbed(:user) }
  let(:controller) { double('ApplicationController') }
  let(:session) { {} }

  let(:instance) { described_class.new(controller: controller) }

  subject { instance.call(input_user) }

  describe 'session' do
    context 'with an SSO provider' do
      let(:sso_provider) do
        {
          name: 'saml',
          retain_from_session: %i[foo bar]
        }
      end

      before do
        allow(::OpenProject::Plugins::AuthPlugin)
          .to(receive(:login_provider_for))
          .and_return sso_provider

        allow(controller)
          .to(receive(:session))
          .and_return session

        allow(controller)
          .to(receive(:reset_session)) do
          session.clear
        end
      end

      context 'if provider retains session values' do
        let(:retained_values) { %i[foo bar] }

        it 'retains present session values' do
          session[:foo] = 'foo value'
          session[:what] = 'should be cleared'

          subject

          expect(session[:foo]).to be_present
          expect(session[:what]).to eq nil
          expect(session[:user_id]).to eq input_user.id
        end
      end
    end
  end
end
