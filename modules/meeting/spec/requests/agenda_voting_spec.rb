# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Meeting agenda voting", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  shared_let(:editor) { create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings manage_agendas] }) }
  let(:meeting) { create(:meeting, project:, agenda_sorting_mode: :vote_based) }
  let(:agenda_item) { create(:meeting_agenda_item, meeting:) }

  before { login_as viewer }

  it "lets viewers vote and returns the reordered section and score" do
    post project_meeting_agenda_item_vote_path(project, meeting, agenda_item),
         params: { reaction: "thumbs_up" }, as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(agenda_item.reload.vote_score).to eq(1)
    expect(Nokogiri::HTML.fragment(response.body).text.squish).to include("Score: 1", "Remove upvote")
    expect(response.body).to include('method="morph"')
  end

  it "shows menu voting to viewers without edit actions or drag handles" do
    agenda_item
    get project_meeting_path(project, meeting)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.text.squish).to include("Upvote", "Downvote", "Score: 0")
    expect(response.parsed_body.at_css(".meeting-infoline").text.squish)
      .to include("Created by #{meeting.author.name}. Agenda sorted by votes. Last updated")
    expect(response.body).not_to include(edit_project_meeting_agenda_item_path(project, meeting, agenda_item))
    expect(response.body).not_to include('draggable-type="agenda-item"')
    expect(response.parsed_body.css(".op-meeting-agenda-item-vote-score button").size).to eq(2)
  end

  it "rejects voting by a user without view permission" do
    login_as create(:user)
    post project_meeting_agenda_item_vote_path(project, meeting, agenda_item),
         params: { reaction: "thumbs_up" }, as: :turbo_stream

    expect(response).to have_http_status(:forbidden)
    expect(agenda_item.emoji_reactions).to be_empty
  end

  it "does not allow voting on an item from another meeting" do
    other_item = create(:meeting_agenda_item)
    post project_meeting_agenda_item_vote_path(project, meeting, other_item),
         params: { reaction: "thumbs_up" }, as: :turbo_stream

    expect(response).to have_http_status(:not_found)
    expect(other_item.emoji_reactions).to be_empty
  end

  it "allows editors to open the sorting dialog" do
    login_as editor
    get agenda_sorting_dialog_project_meeting_path(project, meeting), as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sorting mode", "Manual", "Vote-based")
  end

  it "allows editors to change sorting mode without changing positions" do
    login_as editor
    agenda_item

    put update_agenda_sorting_project_meeting_path(project, meeting),
        params: { meeting: { agenda_sorting_mode: "manual", lock_version: meeting.lock_version } }, as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(meeting.reload).to be_agenda_sorting_manual
    expect(agenda_item.reload.position).to eq(1)
    expect(response.body).not_to include("Agenda sorted by votes.")
  end

  it "rejects changing sorting mode as a viewer" do
    put update_agenda_sorting_project_meeting_path(project, meeting),
        params: { meeting: { agenda_sorting_mode: "manual", lock_version: meeting.lock_version } }, as: :turbo_stream

    expect(response).to have_http_status(:forbidden)
    expect(meeting.reload).to be_agenda_sorting_vote_based
  end

  it "rejects move actions without changing positions" do
    login_as editor
    first_item = create(:meeting_agenda_item, meeting:)
    agenda_item

    put move_project_meeting_agenda_item_path(project, meeting, agenda_item),
        params: { move_to: "highest" }, as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Agenda items are ordered by votes")
    expect(agenda_item.reload.position).to eq(2)
    expect(first_item.reload.position).to eq(1)
  end

  it "rejects drag ordering without changing positions" do
    login_as editor
    first_item = create(:meeting_agenda_item, meeting:)
    agenda_item

    put drop_project_meeting_agenda_item_path(project, meeting, agenda_item),
        params: { target_id: agenda_item.meeting_section_id, position: 1 }, as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Agenda items are ordered by votes")
    expect(agenda_item.reload.position).to eq(2)
    expect(first_item.reload.position).to eq(1)
  end

  it "repositions a new zero-score item above negatively scored items" do
    login_as editor
    agenda_item.emoji_reactions.create!(user: viewer, reaction: :thumbs_down)

    post project_meeting_agenda_items_path(project, meeting),
         params: { meeting_agenda_item: { title: "New item", meeting_section_id: agenda_item.meeting_section_id } },
         as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(meeting.ordered_agenda_items.map(&:title)).to eq(["New item", agenda_item.title])
    expect(response.body.index("New item")).to be < response.body.index(agenda_item.title)
  end
end
