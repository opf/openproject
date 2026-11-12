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

RSpec.describe Avatars::GroupsController do
  let(:current_user) { create(:admin) }
  let(:enabled) { true }
  let(:group) { create(:group) }

  before do
    allow(User).to receive(:current).and_return current_user
    allow(OpenProject::Avatars::AvatarManager).to receive(:local_avatars_enabled?).and_return enabled
  end

  describe "#update_settings" do
    it "updates the group's avatar and returns to the group edit page" do
      patch :update_settings, params: { id: group.id, avatar_type: "initials", avatar_text: "🚀", avatar_color: "#123456" }

      expect(response).to redirect_to edit_group_path(group)
      expect(group.reload.avatar_type).to eq "initials"
      expect(group.avatar_text).to eq "🚀"
      expect(group.avatar_color).to eq "#123456"
    end

    it "never allows Gravatar for a group" do
      patch :update_settings, params: { id: group.id, avatar_type: "gravatar" }

      expect(flash[:error]).to be_present
      expect(group.reload.avatar_type).to be_nil
    end

    context "as a non-admin" do
      let(:current_user) { create(:user) }

      it "forbids changing the settings" do
        patch :update_settings, params: { id: group.id, avatar_type: "initials" }

        expect(response).to have_http_status :forbidden
        expect(group.reload.avatar_type).to be_nil
      end
    end
  end

  describe "#destroy" do
    it "calls the service for delete" do
      service = instance_double(Avatars::UpdateService)
      allow(Avatars::UpdateService).to receive(:new).and_return(service)
      allow(service).to receive(:destroy).and_return(ServiceResult.success(result: "message"))

      delete :destroy, params: { id: group.id }
      expect(flash[:notice]).to include "message"
      expect(response.body).to include 'action="reload"'
    end
  end
end
