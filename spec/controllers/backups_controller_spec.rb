#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

RSpec.describe Admin::BackupsController, skip_2fa_stage: true do
  context "with an OmniAuth user (a user without a password)" do
    let(:user) { create :omniauth_user, admin: true }

    before do
      login_as user
    end

    describe '#perform_token_reset' do
      before do
        post 'perform_token_reset'
      end

      it 'redirects to the authentication endpoint prompting for consent' do
        expect(response).to redirect_to "/auth/concierge?prompt=consent"
      end
    end

    describe '#reset_token' do
      before do
        expect(Token::Backup.count).to eq 0

        allow_any_instance_of(ActionDispatch::Flash::FlashHash)
          .to receive(:[])
          .and_call_original

        allow_any_instance_of(ActionDispatch::Flash::FlashHash)
          .to receive(:[])
          .with(:omniauth_consent_user_uid)
          .and_return(user.identity_url.split(":").last)

        get 'reset_token'
      end

      it 'redirects back to the new backup page' do
        expect(response).to redirect_to "/admin/backups/new"
      end

      it 'creates a new backup token' do
        expect(Token::Backup.count).to eq 1
      end

      it 'shows the backup token in a flash message' do
        expect(flash[:warning].first).to include "A new Backup token"
      end
    end
  end
end
