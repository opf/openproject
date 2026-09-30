# frozen_string_literal: true

#-- copyright
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../../spec_helper"
require_relative "../../shared_examples"

RSpec.describe Avatars::AvatarController do
  include_context "there are users with and without avatars"
  let(:enabled) { true }

  before do
    allow(OpenProject::Avatars::AvatarManager).to receive(:local_avatars_enabled?).and_return enabled
  end

  describe ":show" do
    let(:redirect_path) { user_avatar_url(target_user.id) }
    let(:action) { get :show, params: { id: target_user.id } }

    context "as anonymous" do
      let(:target_user) { user_with_avatar }
      let(:current_user) { User.anonymous }

      it_behaves_like "an action checked for required login"
    end

    describe "when logged in" do
      let(:user) { create(:user) }

      before do
        login_as user
        action
      end

      context "when avatars enabled" do
        context "when user has avatar" do
          let(:target_user) { user_with_avatar }

          it "renders the send file" do
            expect(response).to have_http_status :ok
          end
        end

        context "when user has no avatar" do
          let(:target_user) { user_without_avatar }

          it "renders 404" do
            expect(response).to have_http_status :not_found
          end
        end
      end

      context "when avatars disabled" do
        let(:enabled) { false }
        let(:target_user) { user_with_avatar }

        it "renders a 404" do
          expect(response).to have_http_status :not_found
        end
      end
    end
  end
end
