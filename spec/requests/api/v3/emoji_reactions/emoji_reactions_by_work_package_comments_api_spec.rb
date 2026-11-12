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

require "spec_helper"
require "rack/test"

RSpec.describe API::V3::EmojiReactions::EmojiReactionsByWorkPackageCommentsAPI do
  include API::V3::Utilities::PathHelper

  let(:project) { work_package.project }
  let(:work_package) { create(:work_package) }
  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:admin) { create(:admin) }
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) do
    %i(view_work_packages add_work_package_comments view_internal_comments)
  end

  let(:activity) { work_package.journals.first }
  let!(:emoji_reaction) { create(:emoji_reaction, reactable: activity, user: current_user) }

  before do
    allow(User).to receive(:current).and_return(current_user)
  end

  describe "GET /api/v3/work_packages/:id/activities/emoji_reactions" do
    context "when user has permission to view work package" do
      before do
        get api_v3_paths.emoji_reactions_by_work_package_comments(work_package.id)
      end

      it "succeeds" do
        expect(last_response).to have_http_status :ok
      end

      it "returns the emoji reactions" do
        expect(last_response.body)
          .to be_json_eql(1.to_json)
          .at_path("total")

        expect(last_response.body)
          .to be_json_eql(1.to_json)
          .at_path("count")

        expect(last_response.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        expect(last_response.body)
          .to be_json_eql("#{activity.id}-#{emoji_reaction.reaction}".to_json)
          .at_path("_embedded/elements/0/id")

        expect(last_response.body)
          .to be_json_eql(emoji_reaction.emoji.to_json)
          .at_path("_embedded/elements/0/emoji")
      end
    end

    context "when user does not have permission to view work package" do
      let(:current_user) { create(:user) }

      before do
        get api_v3_paths.emoji_reactions_by_work_package_comments(work_package.id)
      end

      it "fails with HTTP Not Found" do
        expect(last_response).to have_http_status :not_found
      end
    end

    context "when the work package has internal activities" do
      let(:internal_comment) do
        work_package.add_journal(user: current_user, notes: "Internal comment", internal: true)
        work_package.save(validate: false)
        work_package.journals.last
      end
      let!(:internal_emoji_reaction) { create(:emoji_reaction, reactable: internal_comment, user: current_user) }

      before do
        project.enabled_internal_comments = true
        project.save!
      end

      context "and user has permission to view internal comments", with_ee: [:internal_comments] do
        before do
          get api_v3_paths.emoji_reactions_by_work_package_comments(work_package.id)
        end

        it "succeeds" do
          expect(last_response).to have_http_status :ok
        end

        it "returns all emoji reactions including internal ones" do
          expect(last_response.body)
            .to be_json_eql(2.to_json)
            .at_path("total")

          expect(last_response.body)
            .to be_json_eql(internal_emoji_reaction.emoji.to_json)
            .at_path("_embedded/elements/1/emoji")

          expect(last_response.body)
            .to be_json_eql(internal_emoji_reaction.reaction.to_json)
            .at_path("_embedded/elements/1/reaction")
        end
      end

      context "and user does not have permission to view internal comments" do
        before do
          role.role_permissions
            .find_by(permission: "view_internal_comments")
            .destroy
          get api_v3_paths.emoji_reactions_by_work_package_comments(work_package.id)
        end

        it "succeeds but only returns non-internal emoji reactions" do
          expect(last_response).to have_http_status :ok
          expect(last_response.body)
            .to be_json_eql(1.to_json)
            .at_path("total")
        end
      end
    end
  end
end
