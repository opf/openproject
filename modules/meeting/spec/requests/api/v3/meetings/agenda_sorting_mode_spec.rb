# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 Meeting sorting mode", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:permissions) { %i[view_meetings create_meetings edit_meetings] }
  let(:current_user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:meeting) { create(:meeting, project:, author: current_user, agenda_sorting_mode: :vote_based) }

  before { login_as current_user }

  it "returns the sorting mode as a string" do
    get api_v3_paths.meeting(meeting.id)

    expect(last_response).to have_http_status(:ok)
    expect(last_response.body).to be_json_eql('"vote_based"').at_path("agendaSortingMode")
  end

  it "lists both allowed values in the update form schema" do
    post api_v3_paths.meeting_form(meeting.id), { lockVersion: meeting.lock_version }.to_json

    expect(last_response).to have_http_status(:ok)
    expect(last_response.body).to be_json_eql(%w[manual vote_based].to_json)
      .at_path("_embedded/schema/agendaSortingMode/_embedded/allowedValues")
    expect(last_response.body).to be_json_eql('"vote_based"').at_path("_embedded/payload/agendaSortingMode")
  end

  describe "creation" do
    let(:body) do
      {
        title: "Voting meeting",
        startTime: 1.day.from_now.iso8601,
        duration: "PT1H",
        _links: { project: { href: api_v3_paths.project(project.id) } }
      }
    end

    it "defaults to manual sorting when omitted" do
      post api_v3_paths.meetings, body.to_json

      expect(last_response).to have_http_status(:created)
      expect(last_response.body).to be_json_eql('"manual"').at_path("agendaSortingMode")
    end

    it "creates a meeting in vote-based mode" do
      post api_v3_paths.meetings, body.merge(agendaSortingMode: "vote_based").to_json

      expect(last_response).to have_http_status(:created)
      expect(Meeting.find(JSON.parse(last_response.body)["id"])).to be_agenda_sorting_vote_based
    end

    it "rejects invalid sorting modes" do
      expect do
        post api_v3_paths.meetings, body.merge(agendaSortingMode: "votes").to_json
      end.not_to change(Meeting, :count)

      expect(last_response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "updates" do
    %w[manual vote_based].each do |mode|
      it "accepts #{mode}" do
        meeting.update!(agenda_sorting_mode: mode == "manual" ? :vote_based : :manual)

        patch api_v3_paths.meeting(meeting.id), { agendaSortingMode: mode, lockVersion: meeting.lock_version }.to_json

        expect(last_response).to have_http_status(:ok)
        expect(meeting.reload.agenda_sorting_mode).to eq(mode)
        expect(last_response.body).to be_json_eql(mode.to_json).at_path("agendaSortingMode")
      end
    end

    ["votes", "", nil, 1, true].each do |mode|
      it "rejects #{mode.inspect} without changing the mode" do
        patch api_v3_paths.meeting(meeting.id), { agendaSortingMode: mode, lockVersion: meeting.lock_version }.to_json

        expect(last_response).to have_http_status(:unprocessable_entity)
        expect(meeting.reload).to be_agenda_sorting_vote_based
      end
    end

    context "with view permission only" do
      let(:permissions) { %i[view_meetings] }

      it "requires edit_meetings to change the mode" do
        patch api_v3_paths.meeting(meeting.id), { agendaSortingMode: "manual", lockVersion: meeting.lock_version }.to_json

        expect(last_response).to have_http_status(:forbidden)
        expect(meeting.reload).to be_agenda_sorting_vote_based
      end
    end
  end
end
