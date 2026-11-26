# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 Meeting Outcome update agenda item reassignment", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:source_project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:target_project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:author) { create(:user) }

  shared_let(:source_meeting) { create(:meeting, project: source_project, author:, state: :in_progress) }
  shared_let(:target_meeting) { create(:meeting, project: target_project, author:, state: :in_progress) }
  shared_let(:source_item) { create(:meeting_agenda_item, meeting: source_meeting, author:) }
  shared_let(:target_item) { create(:meeting_agenda_item, meeting: target_meeting, author:) }
  let!(:outcome) do
    create(:meeting_outcome, meeting_agenda_item: source_item, author:, notes: "Original notes")
  end

  let(:current_user) do
    create(:user, member_with_permissions: {
             source_project => %i[view_meetings],
             target_project => %i[view_meetings manage_outcomes]
           })
  end

  let(:path) { api_v3_paths.meeting_outcome(outcome.id) }
  let(:body) do
    {
      notes: { raw: "Changed notes" },
      _links: {
        agendaItem: {
          href: api_v3_paths.meeting_agenda_item(target_item.id)
        }
      }
    }.to_json
  end

  before do
    login_as current_user
  end

  subject(:response) { patch path, body }

  it "does not reassign the outcome without permission in the source project" do
    expect(response).to have_http_status(:unprocessable_content)
    expect(outcome.reload).to have_attributes(
      meeting_agenda_item_id: source_item.id,
      notes: "Original notes"
    )
  end

  context "with permission in the source and destination projects" do
    let(:current_user) do
      create(:user, member_with_permissions: {
               source_project => %i[view_meetings manage_outcomes],
               target_project => %i[view_meetings manage_outcomes]
             })
    end

    it "does not reassign the outcome" do
      expect(response).to have_http_status(:unprocessable_content)
      expect(outcome.reload).to have_attributes(
        meeting_agenda_item_id: source_item.id,
        notes: "Original notes"
      )
    end

    context "when linking the current agenda item" do
      let(:body) do
        {
          notes: { raw: "Changed notes" },
          _links: {
            agendaItem: {
              href: api_v3_paths.meeting_agenda_item(source_item.id)
            }
          }
        }.to_json
      end

      it "updates the notes" do
        expect(response).to have_http_status(:ok)
        expect(outcome.reload).to have_attributes(
          meeting_agenda_item_id: source_item.id,
          notes: "Changed notes"
        )
      end
    end
  end
end
