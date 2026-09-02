# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# ++

require "spec_helper"

RSpec.describe "My::AutoLoginTokensController",
               :skip_csrf,
               type: :rails_request,
               with_settings: { autologin: 7 } do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe "DELETE /my/auto_login_tokens/:id" do
    let!(:autologin_token) do
      create(:autologin_token,
             user:,
             data: { browser: "Firefox", browser_version: "142", platform: "macOS" })
    end

    let!(:linked_sql_session1) do
      create(:user_session,
             user:,
             data: { browser: "Firefox", browser_version: "142", platform: "macOS" })
    end

    let!(:linked_sql_session2) do
      create(:user_session,
             user:,
             data: { browser: "Firefox", browser_version: "142", platform: "macOS" })
    end

    let!(:unlinked_sql_session) do
      create(:user_session,
             user:,
             data: { browser: "Chrome", browser_version: "120", platform: "Windows" })
    end

    let!(:linked_session1) do
      Sessions::UserSession.find_by(session_id: linked_sql_session1.session_id)
    end

    let!(:linked_session2) do
      Sessions::UserSession.find_by(session_id: linked_sql_session2.session_id)
    end

    let!(:unlinked_session) do
      Sessions::UserSession.find_by(session_id: unlinked_sql_session.session_id)
    end

    let!(:autologin_session_link1) do
      Sessions::AutologinSessionLink.create(token: autologin_token, session: linked_session1)
    end

    let!(:autologin_session_link2) do
      Sessions::AutologinSessionLink.create(token: autologin_token, session: linked_session2)
    end

    let!(:other_token) { create(:autologin_token, user:) }
    let!(:other_sql_session) { create(:user_session, user:) }
    let!(:other_session) { Sessions::UserSession.find_by(session_id: other_sql_session.session_id) }
    let!(:other_link) { Sessions::AutologinSessionLink.create(token: other_token, session: other_session) }

    let!(:other_user) { create(:user) }
    let!(:other_user_token) { create(:autologin_token, user: other_user) }

    it "deletes the autologin token and all linked sessions" do
      delete "/my/auto_login_tokens/#{autologin_token.id}"

      # the subject token is deleted
      expect { autologin_token.reload }.to raise_error(ActiveRecord::RecordNotFound)

      # linked sessions are deleted
      expect { linked_session1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { linked_session2.reload }.to raise_error(ActiveRecord::RecordNotFound)

      # session links are deleted
      expect { autologin_session_link1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { autologin_session_link2.reload }.to raise_error(ActiveRecord::RecordNotFound)

      # unlinked session remains
      expect(unlinked_session.reload).to be_present

      # other token and its linked session remain
      expect(other_token.reload).to be_present
      expect(other_session.reload).to be_present
      expect(other_link.reload).to be_present
    end

    it "prevents deletion of tokens belonging to other users" do
      expect do
        delete "/my/auto_login_tokens/#{other_user_token.id}"
      end.not_to change(Token::AutoLogin, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "handles non-existent token gracefully" do
      expect do
        delete "/my/auto_login_tokens/#{not_existing_id(Token::AutoLogin)}"
      end.not_to change(Token::AutoLogin, :count)

      expect(response).to have_http_status(:not_found)
    end

    context "when token has no linked sessions" do
      let!(:autologin_token_without_sessions) do
        create(:autologin_token, user:)
      end

      it "deletes only the token" do
        delete "/my/auto_login_tokens/#{autologin_token_without_sessions.id}"

        expect { autologin_token_without_sessions.reload }.to raise_error(ActiveRecord::RecordNotFound)

        expect { autologin_token.reload }.not_to raise_error
        expect { linked_session1.reload }.not_to raise_error
        expect { linked_session2.reload }.not_to raise_error

        expect(response).to redirect_to(my_sessions_path)
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_delete))
      end
    end
  end
end
