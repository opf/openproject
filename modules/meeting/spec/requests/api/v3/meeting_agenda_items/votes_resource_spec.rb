# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 Meeting agenda item votes", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:permissions) { %i[view_meetings] }
  let(:current_user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:meeting) { create(:meeting, project:, agenda_sorting_mode: :vote_based) }
  let(:agenda_item) { create(:meeting_agenda_item, meeting:) }

  before { login_as current_user }

  route_types = [false, true]
  unavailable_states = %i[closed cancelled]

  { upvote: ["thumbs_up", 1], downvote: ["thumbs_down", -1] }.each do |action, (reaction, score)|
    route_types.each do |nested|
      describe "POST #{action} #{nested ? 'under a meeting' : 'on an agenda item'}" do
        let(:path) do
          api_v3_paths.public_send(:"meeting_agenda_item_#{action}", agenda_item.id, meeting_id: nested ? meeting.id : nil)
        end

        it "allows a viewer to vote and returns the updated score" do
          post path

          expect(last_response).to have_http_status(:ok)
          expect(last_response.body).to be_json_eql(score.to_json).at_path("voteScore")
          expect(agenda_item.emoji_reactions.pluck(:user_id, :reaction)).to eq([[current_user.id, reaction]])
        end

        it "removes the same vote when selected again" do
          agenda_item.emoji_reactions.create!(user: current_user, reaction:)

          post path

          expect(last_response).to have_http_status(:ok)
          expect(last_response.body).to be_json_eql("0").at_path("voteScore")
          expect(agenda_item.emoji_reactions.reload).to be_empty
        end

        it "replaces the opposite vote" do
          opposite = reaction == "thumbs_up" ? "thumbs_down" : "thumbs_up"
          agenda_item.emoji_reactions.create!(user: current_user, reaction: opposite)

          post path

          expect(last_response).to have_http_status(:ok)
          expect(last_response.body).to be_json_eql(score.to_json).at_path("voteScore")
          expect(agenda_item.emoji_reactions.pluck(:reaction)).to eq([reaction])
        end

        context "with manual sorting" do
          it "returns 400 without changing existing votes" do
            agenda_item.emoji_reactions.create!(user: current_user, reaction:)
            meeting.update!(agenda_sorting_mode: :manual)

            post path

            expect(last_response).to have_http_status(:bad_request)
            expect(last_response.body).to be_json_eql('"urn:openproject-org:api:v3:errors:BadRequest"')
              .at_path("errorIdentifier")
            expect(agenda_item.emoji_reactions.pluck(:reaction)).to eq([reaction])
          end
        end

        context "without view permission" do
          let(:permissions) { [] }

          it "returns 404 without recording a vote" do
            post path

            expect(last_response).to have_http_status(:not_found)
            expect(agenda_item.emoji_reactions).to be_empty
          end
        end

        unavailable_states.each do |state|
          context "with a #{state} meeting" do
            let(:meeting) { create(:meeting, project:, agenda_sorting_mode: :vote_based, state:) }

            it "rejects voting without recording a vote" do
              post path

              expect(last_response).to have_http_status(state == :cancelled ? :not_found : :forbidden)
              expect(agenda_item.emoji_reactions).to be_empty
            end
          end
        end

        context "with a backlog item" do
          let(:agenda_item) { create(:meeting_agenda_item, meeting:, meeting_section: meeting.backlog) }

          it "returns 403 without recording a vote" do
            post path

            expect(last_response).to have_http_status(:forbidden)
            expect(agenda_item.emoji_reactions).to be_empty
          end
        end

        context "with a template" do
          let(:meeting) { create(:onetime_template, project:, agenda_sorting_mode: :vote_based) }

          it "returns 403 without recording a vote" do
            post path

            expect(last_response).to have_http_status(:forbidden)
            expect(agenda_item.emoji_reactions).to be_empty
          end
        end

        it "returns 404 for a nonexistent item" do
          post api_v3_paths.public_send(:"meeting_agenda_item_#{action}", 0, meeting_id: nested ? meeting.id : nil)

          expect(last_response).to have_http_status(:not_found)
        end

        if nested
          it "returns 404 for an item in a different meeting" do
            other_meeting = create(:meeting, project:, agenda_sorting_mode: :vote_based)

            post api_v3_paths.public_send(:"meeting_agenda_item_#{action}", agenda_item.id, meeting_id: other_meeting.id)

            expect(last_response).to have_http_status(:not_found)
            expect(agenda_item.emoji_reactions).to be_empty
          end
        end
      end
    end
  end

  it "exposes vote actions only while voting is available" do
    get api_v3_paths.meeting_agenda_item(agenda_item.id)

    expect(last_response.body).to be_json_eql(api_v3_paths.meeting_agenda_item_upvote(agenda_item.id).to_json)
      .at_path("_links/upvote/href")
    expect(last_response.body).to be_json_eql('"post"').at_path("_links/upvote/method")
    expect(last_response.body).to have_json_path("_links/downvote")

    meeting.update!(agenda_sorting_mode: :manual)
    get api_v3_paths.meeting_agenda_item(agenda_item.id)

    expect(last_response.body).not_to have_json_path("_links/upvote")
    expect(last_response.body).not_to have_json_path("_links/downvote")
  end

  it "returns fresh scores in agenda collections after voting" do
    agenda_item
    get api_v3_paths.meeting_agenda_items(meeting_id: meeting.id)
    expect(last_response.body).to be_json_eql("0").at_path("_embedded/elements/0/voteScore")

    post api_v3_paths.meeting_agenda_item_upvote(agenda_item.id)
    get api_v3_paths.meeting_agenda_items(meeting_id: meeting.id)

    expect(last_response.body).to be_json_eql("1").at_path("_embedded/elements/0/voteScore")
  end
end
