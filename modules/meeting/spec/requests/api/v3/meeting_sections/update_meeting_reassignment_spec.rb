# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 Meeting Section update meeting reassignment", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:source_project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:target_project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:author) { create(:user) }

  shared_let(:source_meeting) { create(:meeting, project: source_project, author:) }
  shared_let(:target_meeting) { create(:meeting, project: target_project, author:) }
  shared_let(:section) { create(:meeting_section, meeting: source_meeting, title: "Source Section") }
  let!(:agenda_item) do
    create(:meeting_agenda_item, meeting: source_meeting, meeting_section: section, author:, title: "Agenda item")
  end

  let(:current_user) do
    create(:user, member_with_permissions: {
             source_project => %i[view_meetings],
             target_project => %i[view_meetings manage_agendas]
           })
  end

  let(:path) { api_v3_paths.meeting_section(section.id) }
  let(:body) do
    {
      title: "Reassigned Section",
      _links: {
        meeting: {
          href: api_v3_paths.meeting(target_meeting.id)
        }
      }
    }.to_json
  end

  before do
    login_as current_user
  end

  subject(:response) { patch path, body }

  it "does not reassign the section to another meeting" do
    expect(response).to have_http_status(:unprocessable_entity)
    expect(section.reload).to have_attributes(meeting_id: source_meeting.id, title: "Source Section")
    expect(agenda_item.reload.meeting_section_id).to eq(section.id)
  end
end
