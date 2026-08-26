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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "rack/test"

RSpec.describe API::V3::Activities::ActivitiesAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:project) { create(:project, public: false) }
  let(:work_package) do
    create(:work_package, author: current_user, project:)
  end
  let(:permissions) { %i[view_work_packages edit_work_package_comments] }
  let(:activity) { work_package.journals.first }
  let(:comment) { "This is a new test comment!" }

  shared_examples_for "valid activity request" do |type|
    subject { last_response }

    it "returns an activity of the correct type" do
      expect(subject.body).to be_json_eql(type.to_json).at_path("_type")
      expect(subject.body).to be_json_eql(activity.id.to_json).at_path("id")
    end

    it "responds 200 OK" do
      expect(subject.status).to eq(200)
    end
  end

  shared_examples_for "valid activity patch request" do
    it "updates the activity comment" do
      expect(last_response.body).to be_json_eql(comment.to_json).at_path("comment/raw")
    end

    it "changes the comment" do
      expect(activity.reload.notes).to eql comment
    end
  end

  describe "PATCH /api/v3/activities/:activityId" do
    let(:params) { { comment: } }

    before do
      login_as(current_user)
      patch api_v3_paths.activity(activity.id), params.to_json
    end

    it_behaves_like "valid activity request", "Activity::Comment"

    it_behaves_like "valid activity patch request"

    it_behaves_like "invalid activity request",
                    "Cause type is not set to one of the allowed values." do
      let(:activity) do
        # Invalidating the journal
        work_package.journals.first.tap do |journal|
          journal.cause_type = :invalid
          journal.save(validate: false)
        end
      end

      it_behaves_like "constraint violation" do
        let(:message) { "Cause type is not set to one of the allowed values." }
      end
    end

    context "for an activity created by a different user" do
      let(:activity) do
        work_package.journals.first.tap do |journal|
          # it does not matter that the user does not exist
          journal.update_column(:user_id, 0)
        end
      end

      context "when having the necessary permission" do
        it_behaves_like "valid activity request", "Activity::Comment"

        it_behaves_like "valid activity patch request"
      end

      context "when having only the edit own permission" do
        let(:permissions) { %i[view_work_packages edit_own_work_package_comments] }

        it_behaves_like "unauthorized access"
      end
    end

    context "when having only the edit own permission" do
      let(:permissions) { %i[view_work_packages edit_own_work_package_comments] }

      it_behaves_like "valid activity request", "Activity::Comment"

      it_behaves_like "valid activity patch request"
    end

    context "without sufficient permissions to edit" do
      let(:permissions) { [:view_work_packages] }

      it_behaves_like "unauthorized access"
    end

    context "without sufficient permissions to see" do
      let(:permissions) { [] }

      it_behaves_like "not found"
    end

    context "for a internal journal" do
      let(:activity) do
        work_package.add_journal(user: current_user, notes: "need to know basis", internal: true)
        work_package.save(validate: false)
        work_package.journals.last
      end

      context "when editing OWN journals" do
        context "and the user has permission to edit own internal journals" do
          let(:permissions) do
            %i[view_work_packages view_internal_comments edit_own_internal_comments]
          end

          it_behaves_like "valid activity request", "Activity::Comment"

          it_behaves_like "valid activity patch request"
        end

        context "and the user does not have permission to edit own internal journals" do
          let(:permissions) { %i[view_work_packages view_internal_comments] }

          it_behaves_like "unauthorized access"
        end
      end

      context "when editing OTHERs internal journals" do
        let(:other_user) { create(:user, member_with_permissions: { project => permissions }) }

        context "and the user has permission to edit others internal journals" do
          let(:permissions) do
            %i[view_work_packages view_internal_comments edit_others_internal_comments]
          end

          before do
            login_as(other_user)
          end

          it_behaves_like "valid activity request", "Activity::Comment"

          it_behaves_like "valid activity patch request"
        end

        context "and the user does not have permission to edit others internal journals" do
          let(:permissions) { %i[view_work_packages view_internal_comments] }

          before do
            login_as(other_user)
          end

          it_behaves_like "unauthorized access"
        end
      end
    end

    context "with attachments" do
      let(:attachment1) { create(:attachment, container: nil, author: current_user) }
      let(:attachment2) { create(:attachment, container: nil, author: current_user) }

      let(:comment) do
        <<~HTML
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment1.id}/content">
          Lorem ipsum dolor sit amet
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment2.id}/content">
          consectetur adipiscing elit
        HTML
      end

      it "creates attachment claims" do
        expect(last_response.body).to be_json_eql(comment.to_json).at_path("comment/raw")
        expect(activity.reload.attachments).to contain_exactly(attachment1, attachment2)
      end
    end
  end

  describe "#get api" do
    let(:get_path) { api_v3_paths.activity activity.id }

    before do
      login_as(current_user)
    end

    context "logged in user" do
      before do
        get get_path
      end

      context "for a journal without a comment" do
        it_behaves_like "valid activity request", "Activity"
      end

      context "for a journal with a comment" do
        let(:activity) do
          work_package.journals.first.tap do |journal|
            journal.update_column(:notes, comment)
          end
        end

        it_behaves_like "valid activity request", "Activity::Comment"

        context "and an emoji reaction" do
          let!(:emoji_reaction) do
            create(:emoji_reaction, reactable: activity, user: current_user)
          end

          it "returns the emoji reactions" do
            get get_path

            expect(last_response.body)
              .to be_json_eql("#{activity.id}-#{emoji_reaction.reaction}".to_json)
              .at_path("_embedded/emojiReactions/_embedded/elements/0/id")

            expect(last_response.body)
              .to be_json_eql(emoji_reaction.emoji.to_json)
              .at_path("_embedded/emojiReactions/_embedded/elements/0/emoji")
          end
        end
      end

      context "for a internal journal" do
        let(:activity) do
          work_package.add_journal(user: current_user, notes: "need to know basis", internal: true)
          work_package.save(validate: false)
          work_package.journals.last
        end

        context "and the user has permission to view internal journals" do
          let(:permissions) { %i[view_work_packages view_internal_comments] }

          it_behaves_like "valid activity request", "Activity::Comment"
        end

        context "and the user does not have permission to view internal journals" do
          let(:permissions) { [:view_work_packages] }

          it_behaves_like "not found"
        end
      end

      context "requesting nonexistent activity" do
        let(:get_path) { api_v3_paths.activity(not_existing_id(Journal)) }

        it_behaves_like "not found"
      end

      context "without sufficient permissions" do
        let(:permissions) { [] }

        it_behaves_like "not found"
      end
    end

    context "anonymous user" do
      it_behaves_like "handling anonymous user" do
        let(:project) { create(:project, public: true) }
        let(:path) { get_path }
      end
    end
  end
end
